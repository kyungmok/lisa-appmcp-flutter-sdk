import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lisa_appmcp_flutter_sdk/lisa_appmcp_flutter_sdk.dart';

// ──────────────────────────────────────────────
// Memo Model
// ──────────────────────────────────────────────

class Memo {
  final String id;
  final String message;
  final String from;
  final String to;
  final bool pinned;
  final DateTime createdAt;

  Memo({
    required this.id,
    required this.message,
    required this.from,
    required this.to,
    this.pinned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'from': from,
        'to': to,
        'pinned': pinned,
        'createdAt': formatTime(createdAt),
      };
}

String formatTime(DateTime dt) {
  return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ──────────────────────────────────────────────
// Family colors & avatars
// ──────────────────────────────────────────────

const _familyColors = <String, Color>{
  '엄마': Color(0xFFE91E63),
  '아빠': Color(0xFF2196F3),
  '아들': Color(0xFF4CAF50),
  '딸': Color(0xFFFF9800),
};

const _familyEmoji = <String, String>{
  '엄마': '👩',
  '아빠': '👨',
  '아들': '👦',
  '딸': '👧',
};

Color _colorFor(String name) =>
    _familyColors[name] ?? const Color(0xFF9E9E9E);
String _emojiFor(String name) => _familyEmoji[name] ?? '👤';

// ──────────────────────────────────────────────
// App
// ──────────────────────────────────────────────

void main() => runApp(const FamilyBoardApp());

class FamilyBoardApp extends StatelessWidget {
  const FamilyBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가족 게시판',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final LisaMcpClient _client;
  StreamSubscription? _stateSub;
  McpConnectionState _connState = McpConnectionState.disconnected;

  final List<Memo> _memos = [
    Memo(
      id: 'init_1',
      message: '저녁 7시에 외식! 준비해~',
      from: '엄마',
      to: '모두',
      pinned: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Memo(
      id: 'init_2',
      message: '우유 사와주세요',
      from: '아빠',
      to: '엄마',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Memo(
      id: 'init_3',
      message: '숙제 다 했어요!',
      from: '아들',
      to: '엄마',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _client = LisaMcpClient(
      LisaMcpConfig(
        appId: 'com.webos.app.familyboard',
        port: 9100,
        autoReconnect: true,
      ),
    );
    _registerTools();
    _stateSub = _client.stateChanges.listen((s) {
      if (mounted) setState(() => _connState = s);
    });
    _client.connect().catchError((_) {});
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _client.disconnect();
    _client.dispose();
    super.dispose();
  }

  void _registerTools() {
    _client.registerTool(McpToolDef(
      name: 'post_memo',
      description: '가족 게시판에 메모 남기기. 누가 누구에게 남기는지 지정 가능.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'message': {'type': 'string', 'description': '메모 내용'},
          'from': {'type': 'string', 'description': '보내는 사람'},
          'to': {'type': 'string', 'description': '받는 사람 (생략 시 모두)'},
          'pin': {'type': 'boolean', 'description': '중요 메모 고정'},
        },
        'required': ['message', 'from'],
      },
      handler: (args) async {
        final message = args['message'] as String? ?? '';
        final from = args['from'] as String? ?? '익명';
        final to = args['to'] as String? ?? '모두';
        final pin = args['pin'] as bool? ?? false;

        if (message.isEmpty) {
          return McpToolResult.error('메모 내용을 입력해주세요');
        }

        final memo = Memo(
          id: 'memo_${_nextId++}',
          message: message,
          from: from,
          to: to,
          pinned: pin,
        );
        setState(() => _memos.add(memo));

        final pinLabel = pin ? ' [고정]' : '';
        return McpToolResult.text(
          '메모 등록 완료$pinLabel\nFrom: ${memo.from} → To: ${memo.to}\n"${memo.message}"',
        );
      },
    ));

    _client.registerTool(McpToolDef(
      name: 'read_memos',
      description: '가족 게시판 메모 조회. 특정 사람 대상 또는 전체.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'for': {'type': 'string', 'description': '특정 사람 대상 메모만 조회'},
        },
      },
      handler: (args) async {
        final forPerson = args['for'] as String?;
        var filtered = _memos.toList();
        if (forPerson != null && forPerson.isNotEmpty) {
          filtered = _memos
              .where((m) =>
                  m.to == '모두' ||
                  m.to.contains(forPerson) ||
                  m.from.contains(forPerson))
              .toList();
        }
        if (filtered.isEmpty) {
          return McpToolResult.text('게시판이 비어있습니다');
        }
        filtered.sort((a, b) {
          if (a.pinned && !b.pinned) return -1;
          if (!a.pinned && b.pinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        return McpToolResult.text(
            jsonEncode(filtered.map((m) => m.toJson()).toList()));
      },
    ));

    _client.registerTool(McpToolDef(
      name: 'delete_memo',
      description: '메모 삭제.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'memoId': {'type': 'string', 'description': '삭제할 메모 ID'},
        },
        'required': ['memoId'],
      },
      handler: (args) async {
        final id = args['memoId'] as String? ?? '';
        final idx = _memos.indexWhere((m) => m.id == id);
        if (idx == -1) {
          return McpToolResult.error('메모를 찾을 수 없습니다: $id');
        }
        final removed = _memos[idx];
        setState(() => _memos.removeAt(idx));
        return McpToolResult.text(
            '메모 삭제 완료: "${removed.message}" (by ${removed.from})');
      },
    ));
  }

  List<Memo> get _sortedMemos {
    final list = List<Memo>.from(_memos);
    list.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏠 가족 게시판'),
        actions: [_connectionBadge()],
      ),
      body: _sortedMemos.isEmpty
          ? const Center(
              child: Text('메모가 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _sortedMemos.length,
              itemBuilder: (ctx, i) => _MemoCard(memo: _sortedMemos[i]),
            ),
    );
  }

  Widget _connectionBadge() {
    final (color, label) = switch (_connState) {
      McpConnectionState.connected => (Colors.green, 'Lisa 연결됨'),
      McpConnectionState.connecting => (Colors.orange, '연결 중...'),
      McpConnectionState.disconnected => (Colors.red, '연결 끊김'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Chip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.transparent,
        side: BorderSide.none,
      ),
    );
  }
}

class _MemoCard extends StatelessWidget {
  final Memo memo;
  const _MemoCard({required this.memo});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(memo.from);
    return Card(
      color: color.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_emojiFor(memo.from), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${memo.from} → ${memo.to}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (memo.pinned)
                  const Text('📌', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                memo.message,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatTime(memo.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
