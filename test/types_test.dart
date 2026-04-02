import 'package:test/test.dart';
import 'package:lisa_appmcp_flutter_sdk/lisa_appmcp_flutter_sdk.dart';

void main() {
  group('McpToolResult', () {
    test('text result serializes correctly', () {
      final result = McpToolResult.text('hello');
      final json = result.toJson();
      expect(json['content'], hasLength(1));
      expect(json['content'][0]['type'], 'text');
      expect(json['content'][0]['text'], 'hello');
      expect(json.containsKey('isError'), isFalse);
    });

    test('error result has isError flag', () {
      final result = McpToolResult.error('something broke');
      final json = result.toJson();
      expect(json['isError'], isTrue);
      expect(json['content'][0]['text'], 'something broke');
    });
  });

  group('McpToolDef', () {
    test('toJson includes schema', () {
      final tool = McpToolDef(
        name: 'search',
        description: 'Search stuff',
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'}
          },
        },
        handler: (_) async => McpToolResult.text('ok'),
      );

      final json = tool.toJson();
      expect(json['name'], 'search');
      expect(json['description'], 'Search stuff');
      expect(json['inputSchema']['type'], 'object');
    });
  });

  group('LisaMcpConfig', () {
    test('default wsUrl', () {
      final config = LisaMcpConfig(appId: 'com.test');
      expect(config.wsUrl, 'ws://localhost:9100/mcp/com.test');
    });

    test('custom port', () {
      final config = LisaMcpConfig(appId: 'com.test', port: 8080);
      expect(config.wsUrl, 'ws://localhost:8080/mcp/com.test');
    });

    test('rejects invalid appId with hyphen', () {
      expect(() => LisaMcpConfig(appId: 'com.my-app'), throwsArgumentError);
    });

    test('rejects invalid appId with slash', () {
      expect(() => LisaMcpConfig(appId: '../etc'), throwsArgumentError);
    });

    test('accepts valid appId with dots and underscores', () {
      final config = LisaMcpConfig(appId: 'com.my_app.v2');
      expect(config.appId, 'com.my_app.v2');
    });
  });
}
