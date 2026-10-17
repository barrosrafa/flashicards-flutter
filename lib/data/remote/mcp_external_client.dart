import 'edge_function_client.dart';

/// Client for external Model Context Protocol (MCP) tools via the `mcp` Edge Function.
///
/// Mirrors `src/lib/mcp/external-client.ts` from `app-flashi`.
class McpToolResult {
  const McpToolResult({
    required this.toolName,
    required this.success,
    required this.data,
    this.auditId,
  });

  final String toolName;
  final bool success;
  final Map<String, dynamic> data;
  final String? auditId;
}

class McpExternalClient {
  McpExternalClient({
    EdgeFunctionClient? edgeClient,
  }) : _edgeClient = edgeClient ?? EdgeFunctionClient.instance;

  final EdgeFunctionClient _edgeClient;

  /// Lists available MCP tools exposed by the Flashi `mcp` Edge Function.
  Future<List<String>> listTools() async {
    try {
      final Map<String, dynamic> res = await _edgeClient.invoke(
        'mcp',
        body: <String, dynamic>{
          'method': 'tools/list',
        },
      );
      final List<dynamic> rawTools =
          res['tools'] as List<dynamic>? ?? const <dynamic>[];
      return rawTools
          .map((dynamic item) {
            if (item is Map<String, dynamic>) {
              return item['name']?.toString() ?? '';
            }
            return item.toString();
          })
          .where((String name) => name.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[
        'list_decks',
        'create_note',
        'search_cards',
        'get_due_cards',
        'submit_review',
      ];
    }
  }

  /// Calls a specific MCP tool with [arguments].
  Future<McpToolResult> callTool({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final Map<String, dynamic> res = await _edgeClient.invoke(
      'mcp',
      body: <String, dynamic>{
        'method': 'tools/call',
        'params': <String, dynamic>{
          'name': toolName,
          'arguments': arguments,
        },
      },
    );
    return McpToolResult(
      toolName: toolName,
      success: res['isError'] != true,
      data: (res['result'] as Map<String, dynamic>?) ?? res,
      auditId: res['audit_id']?.toString(),
    );
  }
}
