/// WebSocket connection to appmcp-server for MCP tool serving.
///
/// The app connects to `ws://localhost:{port}/mcp/{appId}` and responds
/// to incoming `tools/call` and `tools/list` JSON-RPC requests.
///
/// Uses `web_socket_channel` for cross-platform support (macOS/Linux/Web).

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'types.dart';

/// Validates appId format: alphanumeric, dots, underscores only.
/// No hyphens (conflicts with dot→hyphen mapping in appmcp-server).
final _appIdPattern = RegExp(r'^[a-zA-Z0-9._]+$');

/// Configuration for the MCP connection.
class LisaMcpConfig {
  /// App identifier (e.g., "com.netflix"). Must match appMCP.json.
  final String appId;

  /// appmcp-server WebSocket port.
  final int port;

  /// appmcp-server host.
  final String host;

  /// Auto-reconnect on disconnect.
  final bool autoReconnect;

  /// Initial reconnect delay (doubles on each retry, max 60s).
  final Duration reconnectDelay;

  /// Maximum reconnect attempts (0 = unlimited).
  final int maxReconnectAttempts;

  LisaMcpConfig({
    required this.appId,
    this.port = 9100,
    this.host = 'localhost',
    this.autoReconnect = true,
    this.reconnectDelay = const Duration(seconds: 2),
    this.maxReconnectAttempts = 0,
  }) {
    if (!_appIdPattern.hasMatch(appId)) {
      throw ArgumentError(
        'Invalid appId "$appId": must match [a-zA-Z0-9._]+',
      );
    }
  }

  String get wsUrl => 'ws://$host:$port/mcp/$appId';
}

/// Connection state.
enum McpConnectionState { disconnected, connecting, connected }

/// Lisa MCP client — connects to appmcp-server and serves tools.
class LisaMcpClient {
  final LisaMcpConfig config;
  final Map<String, McpToolDef> _tools = {};

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  McpConnectionState _state = McpConnectionState.disconnected;
  final _stateController = StreamController<McpConnectionState>.broadcast();
  bool _disposed = false;
  bool _intentionalDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Stream of connection state changes.
  Stream<McpConnectionState> get stateChanges => _stateController.stream;

  /// Current connection state.
  McpConnectionState get state => _state;

  LisaMcpClient(this.config);

  /// Register a tool that LLM can call.
  void registerTool(McpToolDef tool) {
    _tools[tool.name] = tool;
  }

  /// Register multiple tools.
  void registerTools(List<McpToolDef> tools) {
    for (final tool in tools) {
      _tools[tool.name] = tool;
    }
  }

  /// Connect to appmcp-server.
  Future<void> connect() async {
    if (_disposed) return;
    if (_state != McpConnectionState.disconnected) return;

    _intentionalDisconnect = false;
    _setState(McpConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(config.wsUrl));
      // Wait for the connection to be established
      await _channel!.ready.timeout(const Duration(seconds: 10));
      _setState(McpConnectionState.connected);
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _onDisconnected,
        onError: (error) => _onDisconnected(),
      );
    } catch (e) {
      _channel = null;
      _setState(McpConnectionState.disconnected);
      _maybeReconnect();
      rethrow;
    }
  }

  /// Disconnect from appmcp-server.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(McpConnectionState.disconnected);
  }

  /// Dispose resources. Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _stateController.close();
  }

  void _setState(McpConnectionState newState) {
    if (_disposed) return;
    _state = newState;
    _stateController.add(newState);
  }

  void _onDisconnected() {
    _subscription = null;
    _channel = null;
    _setState(McpConnectionState.disconnected);
    if (!_intentionalDisconnect) {
      _maybeReconnect();
    }
  }

  void _maybeReconnect() {
    if (_disposed || !config.autoReconnect || _intentionalDisconnect) return;
    if (config.maxReconnectAttempts > 0 &&
        _reconnectAttempts >= config.maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s, 60s max
    final delay = Duration(
      milliseconds: (config.reconnectDelay.inMilliseconds *
              (1 << (_reconnectAttempts - 1).clamp(0, 5)))
          .clamp(0, 60000),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_disposed && _state == McpConnectionState.disconnected) {
        connect().catchError((_) {});
      }
    });
  }

  void _handleMessage(dynamic data) {
    try {
      final request = jsonDecode(data as String) as Map<String, dynamic>;
      final method = request['method'] as String?;

      switch (method) {
        case 'tools/call':
          _handleToolsCall(request).catchError((e) {
            final id = request['id'];
            _sendResponse({
              'jsonrpc': '2.0',
              'id': id,
              'result': McpToolResult.error('Tool execution failed').toJson(),
            });
          });
          break;
        case 'tools/list':
          _handleToolsList(request);
          break;
        default:
          break;
      }
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[LisaMcpClient] message parse error: $e');
        return true;
      }());
    }
  }

  void _handleToolsList(Map<String, dynamic> request) {
    final id = request['id'];
    final tools = _tools.values.map((t) => t.toJson()).toList();
    _sendResponse({
      'jsonrpc': '2.0',
      'id': id,
      'result': {'tools': tools},
    });
  }

  Future<void> _handleToolsCall(Map<String, dynamic> request) async {
    final id = request['id'];
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final toolName = params['name'] as String? ?? '';
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    final tool = _tools[toolName];

    if (tool == null) {
      _sendResponse({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32601, 'message': 'unknown tool: $toolName'},
      });
      return;
    }

    try {
      final result = await tool.handler(arguments);
      _sendResponse({
        'jsonrpc': '2.0',
        'id': id,
        'result': result.toJson(),
      });
    } catch (e) {
      _sendResponse({
        'jsonrpc': '2.0',
        'id': id,
        'result': McpToolResult.error('Tool execution failed').toJson(),
      });
    }
  }

  void _sendResponse(Map<String, dynamic> response) {
    _channel?.sink.add(jsonEncode(response));
  }
}
