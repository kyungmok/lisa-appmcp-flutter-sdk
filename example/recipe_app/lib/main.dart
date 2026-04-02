import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lisa_appmcp_flutter_sdk/lisa_appmcp_flutter_sdk.dart';

// ──────────────────────────────────────────────
// Recipe Database
// ──────────────────────────────────────────────

final List<Map<String, dynamic>> recipes = [
  {
    'id': 'kimchi_jjigae', 'name': '김치찌개', 'emoji': '🍲',
    'ingredients': ['김치', '돼지고기', '두부', '대파', '고춧가루'],
    'time': 30, 'difficulty': '쉬움',
    'steps': [
      {'step': 1, 'desc': '돼지고기를 한입 크기로 썬다', 'timer': null},
      {'step': 2, 'desc': '냄비에 참기름을 두르고 돼지고기를 볶는다', 'timer': 3},
      {'step': 3, 'desc': '김치를 넣고 함께 볶는다', 'timer': 5},
      {'step': 4, 'desc': '물을 붓고 끓인다', 'timer': 15},
      {'step': 5, 'desc': '두부와 대파를 넣고 마무리', 'timer': 5},
    ],
  },
  {
    'id': 'pasta_aglio', 'name': '알리오 올리오', 'emoji': '🍝',
    'ingredients': ['스파게티', '마늘', '올리브오일', '페퍼론치노', '파슬리'],
    'time': 20, 'difficulty': '쉬움',
    'steps': [
      {'step': 1, 'desc': '끓는 물에 소금 넣고 스파게티 삶기', 'timer': 8},
      {'step': 2, 'desc': '팬에 올리브오일+마늘+페퍼론치노 약불로 볶기', 'timer': 5},
      {'step': 3, 'desc': '삶은 면과 면수 2스푼을 팬에 넣고 섞기', 'timer': 2},
      {'step': 4, 'desc': '파슬리 뿌리고 완성', 'timer': null},
    ],
  },
  {
    'id': 'gyeran_bap', 'name': '계란볶음밥', 'emoji': '🍳',
    'ingredients': ['밥', '계란', '대파', '간장', '참기름'],
    'time': 10, 'difficulty': '매우 쉬움',
    'steps': [
      {'step': 1, 'desc': '계란 2개를 풀어 스크램블한다', 'timer': 2},
      {'step': 2, 'desc': '밥을 넣고 센불에 볶는다', 'timer': 3},
      {'step': 3, 'desc': '간장, 대파 넣고 마무리, 참기름 한 바퀴', 'timer': 2},
    ],
  },
  {
    'id': 'doenjang_jjigae', 'name': '된장찌개', 'emoji': '🫕',
    'ingredients': ['된장', '두부', '감자', '호박', '대파', '고추'],
    'time': 25, 'difficulty': '쉬움',
    'steps': [
      {'step': 1, 'desc': '감자, 호박, 두부를 깍둑썰기한다', 'timer': null},
      {'step': 2, 'desc': '멸치 육수를 끓인다', 'timer': 10},
      {'step': 3, 'desc': '된장을 풀고 감자를 넣어 끓인다', 'timer': 8},
      {'step': 4, 'desc': '호박, 두부, 대파, 고추를 넣고 마무리', 'timer': 5},
    ],
  },
  {
    'id': 'ramyun', 'name': '라면', 'emoji': '🍜',
    'ingredients': ['라면', '계란', '대파'],
    'time': 5, 'difficulty': '매우 쉬움',
    'steps': [
      {'step': 1, 'desc': '물 550ml를 끓인다', 'timer': 3},
      {'step': 2, 'desc': '스프와 면을 넣는다', 'timer': null},
      {'step': 3, 'desc': '계란 넣고 끓이면 완성', 'timer': 4},
    ],
  },
  {
    'id': 'bibimbap', 'name': '비빔밥', 'emoji': '🍚',
    'ingredients': ['밥', '시금치', '콩나물', '당근', '계란', '고추장'],
    'time': 30, 'difficulty': '보통',
    'steps': [
      {'step': 1, 'desc': '시금치, 콩나물 각각 데친다', 'timer': 5},
      {'step': 2, 'desc': '당근을 채썰어 볶는다', 'timer': 3},
      {'step': 3, 'desc': '계란 프라이를 만든다', 'timer': 3},
      {'step': 4, 'desc': '밥 위에 나물, 계란 올리고 고추장 넣어 비빈다', 'timer': null},
    ],
  },
  {
    'id': 'tteokbokki', 'name': '떡볶이', 'emoji': '🌶️',
    'ingredients': ['떡', '어묵', '고추장', '고춧가루', '설탕', '대파'],
    'time': 20, 'difficulty': '쉬움',
    'steps': [
      {'step': 1, 'desc': '물에 고추장, 고춧가루, 설탕, 간장으로 양념장', 'timer': null},
      {'step': 2, 'desc': '물 끓으면 떡과 어묵 넣기', 'timer': 5},
      {'step': 3, 'desc': '양념장 넣고 졸이기', 'timer': 10},
      {'step': 4, 'desc': '대파 넣고 마무리', 'timer': 2},
    ],
  },
];

// ──────────────────────────────────────────────
// App
// ──────────────────────────────────────────────

void main() => runApp(const RecipeApp());

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트 레시피',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFF6B35),
        useMaterial3: true,
      ),
      home: const RecipeScreen(),
    );
  }
}

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late final LisaMcpClient _client;
  StreamSubscription? _stateSub;
  McpConnectionState _connState = McpConnectionState.disconnected;

  String? _selectedRecipeId;
  final List<_ActiveTimer> _timers = [];

  @override
  void initState() {
    super.initState();
    _client = LisaMcpClient(
      LisaMcpConfig(appId: 'com.webos.app.recipe', port: 9100, autoReconnect: true),
    );
    _registerTools();
    _stateSub = _client.stateChanges.listen((s) {
      if (mounted) setState(() => _connState = s);
    });
    _client.connect().catchError((_) {});
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _stateSub?.cancel();
    _client.disconnect();
    _client.dispose();
    super.dispose();
  }

  void _registerTools() {
    _client.registerTool(McpToolDef(
      name: 'search_recipe',
      description: '레시피 검색. 재료나 요리 이름으로 검색 가능.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': '검색어 (재료명 또는 요리명)'},
        },
        'required': ['query'],
      },
      handler: (args) async {
        final query = (args['query'] as String? ?? '').toLowerCase().replaceAll(' ', '');
        if (query.isEmpty) return McpToolResult.error('"query"를 입력해주세요');
        final results = recipes.where((r) {
          final name = r['name'].toString().toLowerCase().replaceAll(' ', '');
          final ingredients = (r['ingredients'] as List).map((i) => i.toString().toLowerCase());
          return name.contains(query) || ingredients.any((i) => i.contains(query));
        }).map((r) => <String, dynamic>{
              'id': r['id'], 'name': r['name'],
              'ingredients': r['ingredients'],
              'time': '${r['time']}분', 'difficulty': r['difficulty'],
            }).toList();
        if (results.isEmpty) return McpToolResult.text('검색 결과 없음: "$query"');
        return McpToolResult.text(jsonEncode(results));
      },
    ));

    _client.registerTool(McpToolDef(
      name: 'get_steps',
      description: '레시피 조리 단계 조회.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'recipeId': {'type': 'string', 'description': '레시피 ID'},
        },
        'required': ['recipeId'],
      },
      handler: (args) async {
        final id = args['recipeId'] as String? ?? '';
        final recipe = recipes.where((r) => r['id'] == id).firstOrNull;
        if (recipe == null) return McpToolResult.error('레시피를 찾을 수 없습니다: $id');
        setState(() => _selectedRecipeId = id);
        final steps = (recipe['steps'] as List).map((s) {
          final step = s as Map<String, dynamic>;
          final m = <String, dynamic>{'step': step['step'], 'description': step['desc']};
          if (step['timer'] != null) m['suggestedTimer'] = '${step['timer']}분';
          return m;
        }).toList();
        return McpToolResult.text(jsonEncode({
          'name': recipe['name'], 'totalTime': '${recipe['time']}분', 'steps': steps,
        }));
      },
    ));

    _client.registerTool(McpToolDef(
      name: 'set_timer',
      description: '요리 타이머 설정. 분 단위.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'minutes': {'type': 'integer', 'description': '타이머 시간 (분)'},
          'label': {'type': 'string', 'description': '타이머 라벨'},
        },
        'required': ['minutes'],
      },
      handler: (args) async {
        final minutes = (args['minutes'] as num?)?.toInt() ?? 0;
        final label = args['label'] as String? ?? '요리 타이머';
        if (minutes <= 0 || minutes > 180) {
          return McpToolResult.error('타이머는 1~180분 사이로 설정해주세요');
        }
        _addTimer(label, minutes);
        return McpToolResult.text('⏰ 타이머 설정 완료: $label ($minutes분)');
      },
    ));
  }

  void _addTimer(String label, int minutes) {
    final at = _ActiveTimer(
      label: label,
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
    );
    at.timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        at.remainingSeconds--;
        if (at.remainingSeconds <= 0) {
          at.cancel();
          at.done = true;
        }
      });
    });
    setState(() => _timers.add(at));
  }

  void _removeTimer(int index) {
    _timers[index].cancel();
    setState(() => _timers.removeAt(index));
  }

  Map<String, dynamic>? get _selectedRecipe =>
      _selectedRecipeId == null ? null :
      recipes.where((r) => r['id'] == _selectedRecipeId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍳 스마트 레시피'),
        actions: [_connectionBadge()],
      ),
      body: Row(
        children: [
          // Left: recipe list
          SizedBox(
            width: 280,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: recipes.length,
              itemBuilder: (ctx, i) {
                final r = recipes[i];
                final selected = r['id'] == _selectedRecipeId;
                return Card(
                  color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
                  child: ListTile(
                    leading: Text(r['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 28)),
                    title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${r['time']}분 · ${r['difficulty']}'),
                    onTap: () => setState(() => _selectedRecipeId = r['id']),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Center: recipe detail
          Expanded(
            flex: 2,
            child: _selectedRecipe == null
                ? const Center(child: Text('레시피를 선택하세요', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : _RecipeDetail(recipe: _selectedRecipe!),
          ),
          // Right: timers
          if (_timers.isNotEmpty) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('⏰ 타이머', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _timers.length,
                      itemBuilder: (ctx, i) => _TimerTile(
                        timer: _timers[i],
                        onDismiss: () => _removeTimer(i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

class _RecipeDetail extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const _RecipeDetail({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final steps = recipe['steps'] as List;
    final ingredients = recipe['ingredients'] as List;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Row(
          children: [
            Text(recipe['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('⏱ ${recipe['time']}분  ·  ${recipe['difficulty']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Ingredients
        Text('재료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[300])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ingredients.map((i) => Chip(label: Text(i.toString()))).toList(),
        ),
        const SizedBox(height: 24),
        // Steps
        Text('조리 순서', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[300])),
        const SizedBox(height: 12),
        ...steps.map((s) {
          final step = s as Map<String, dynamic>;
          final timer = step['timer'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: Text('${step['step']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['desc'], style: const TextStyle(fontSize: 16)),
                      if (timer != null)
                        Text('⏰ ${timer}분', style: TextStyle(fontSize: 13, color: Colors.orange[300])),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TimerTile extends StatelessWidget {
  final _ActiveTimer timer;
  final VoidCallback onDismiss;
  const _TimerTile({required this.timer, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final min = timer.remainingSeconds ~/ 60;
    final sec = timer.remainingSeconds % 60;
    final progress = 1.0 - (timer.remainingSeconds / timer.totalSeconds);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        color: timer.done ? Colors.green.withValues(alpha: 0.2) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(timer.label, style: const TextStyle(fontWeight: FontWeight.bold))),
                  GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, size: 16)),
                ],
              ),
              const SizedBox(height: 8),
              if (timer.done)
                const Text('✅ 완료!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
              else ...[
                Text('${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 24, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveTimer {
  final String label;
  final int totalSeconds;
  int remainingSeconds;
  bool done;
  Timer? timer;

  _ActiveTimer({
    required this.label,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.done = false,
  });

  void cancel() => timer?.cancel();
}
