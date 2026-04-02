# lisa_appmcp_flutter_sdk

Flutter/Dart SDK for integrating app AI tools with Lisa via MCP protocol.

## Overview

Your app registers **tools** (AI-callable functions) that Lisa's LLM can invoke.
The SDK handles WebSocket connection to `appmcp-server` and JSON-RPC message routing.

```
┌─────────────┐  WS   ┌──────────────┐  stdio  ┌──────┐
│  Your App   │◄─────►│ appmcp-server │◄───────►│ Lisa │
│  (Flutter)  │  MCP  │              │  MCP    │      │
└─────────────┘       └──────────────┘         └──────┘
```

## Quick Start

### 1. Create `appMCP.json`

Place in `/var/lisa/apps/{appId}/appMCP.json`:

```json
{
  "appId": "com.myapp",
  "name": "My App",
  "version": "1.0.0",
  "launch": {
    "method": "luna-send",
    "uri": "luna://com.webos.service.applicationManager/launch",
    "params": { "id": "com.myapp" }
  },
  "tools": [
    {
      "name": "search",
      "description": "Search content",
      "inputSchema": {
        "type": "object",
        "properties": { "query": { "type": "string" } },
        "required": ["query"]
      }
    }
  ]
}
```

### 2. Add dependency

```yaml
dependencies:
  lisa_appmcp_flutter_sdk:
    git:
      url: https://github.com/rordd/lisa-appmcp-flutter-sdk.git
```

### 3. Register tools and connect

```dart
import 'package:lisa_appmcp_flutter_sdk/lisa_appmcp_flutter_sdk.dart';

final client = LisaMcpClient(LisaMcpConfig(appId: 'com.myapp'));

client.registerTool(McpToolDef(
  name: 'search',
  description: 'Search content',
  inputSchema: {
    'type': 'object',
    'properties': {'query': {'type': 'string'}},
    'required': ['query'],
  },
  handler: (args) async {
    final results = await api.search(args['query']);
    return McpToolResult.text(jsonEncode(results));
  },
));

await client.connect(); // ws://localhost:9100/mcp/com.myapp
```

## Features

- **Auto-reconnect**: Reconnects automatically on disconnect (configurable)
- **Connection state stream**: Listen to `client.stateChanges`
- **Error handling**: Tool errors are returned as MCP error results
- **Zero config**: Default port 9100, localhost

## Tool Name Rules

- Tool names in `appMCP.json` are local (e.g., `search`)
- `appmcp-server` adds prefix: `com-myapp__search` (dots → hyphens)
- Your handler receives the **original** name (`search`)

## API

### `LisaMcpClient`

| Method | Description |
|--------|-------------|
| `registerTool(McpToolDef)` | Register a single tool |
| `registerTools(List<McpToolDef>)` | Register multiple tools |
| `connect()` | Connect to appmcp-server |
| `disconnect()` | Disconnect |
| `dispose()` | Clean up resources |

### `McpToolResult`

| Factory | Description |
|---------|-------------|
| `McpToolResult.text(String)` | Single text result |
| `McpToolResult.error(String)` | Error result |
