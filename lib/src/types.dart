/// MCP protocol types for Lisa app integration.

/// Tool definition — describes an AI-callable function.
class McpToolDef {
  /// Tool name (e.g., "search", "play").
  final String name;

  /// Human-readable description for LLM.
  final String description;

  /// JSON Schema for input parameters.
  final Map<String, dynamic> inputSchema;

  /// Handler function: receives arguments, returns result text.
  final Future<McpToolResult> Function(Map<String, dynamic> arguments) handler;

  McpToolDef({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };
}

/// Result from a tool execution.
class McpToolResult {
  final List<McpContent> content;
  final bool isError;

  McpToolResult({required this.content, this.isError = false});

  /// Convenience: single text result.
  factory McpToolResult.text(String text) => McpToolResult(
        content: [McpContent.text(text)],
      );

  /// Convenience: error result.
  factory McpToolResult.error(String message) => McpToolResult(
        content: [McpContent.text(message)],
        isError: true,
      );

  Map<String, dynamic> toJson() => {
        'content': content.map((c) => c.toJson()).toList(),
        if (isError) 'isError': true,
      };
}

/// Content block in a tool result.
class McpContent {
  final String type;
  final String text;

  McpContent({required this.type, required this.text});

  factory McpContent.text(String text) =>
      McpContent(type: 'text', text: text);

  Map<String, dynamic> toJson() => {'type': type, 'text': text};
}
