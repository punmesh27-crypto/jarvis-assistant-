/// Simple data model for a single chat message.
/// Kept intentionally minimal in Step 1 - no persistence yet.
/// Step 4 will add saving/loading this model to local storage.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
