/// Lisa MCP Client — Flutter/Dart SDK for app AI tool integration.
///
/// Apps register tools that LLM can call via Lisa's MCP infrastructure.
///
/// ```dart
/// import 'package:lisa_appmcp_flutter_sdk/lisa_appmcp_flutter_sdk.dart';
///
/// final client = LisaMcpClient(LisaMcpConfig(appId: 'com.myapp'));
///
/// client.registerTool(McpToolDef(
///   name: 'search',
///   description: 'Search content',
///   inputSchema: {
///     'type': 'object',
///     'properties': {'query': {'type': 'string'}},
///     'required': ['query'],
///   },
///   handler: (args) async {
///     final results = await myApi.search(args['query']);
///     return McpToolResult.text(jsonEncode(results));
///   },
/// ));
///
/// await client.connect();
/// ```
library lisa_appmcp_flutter_sdk;

export 'src/types.dart';
export 'src/mcp_connection.dart';
