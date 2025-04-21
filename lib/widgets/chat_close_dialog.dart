import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatCloseDialog extends StatelessWidget {
  final String roomId;
  final VoidCallback? onSuccess;

  const ChatCloseDialog({super.key, required this.roomId, this.onSuccess});

  // Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String roomId,
    VoidCallback? onSuccess,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => ChatCloseDialog(roomId: roomId, onSuccess: onSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Chat Room'),
      content: const Text(
        'Are you sure you want to close this chat room? '
        'All members will be notified and no new messages will be allowed. '
        'The room and its messages will be automatically deleted after 7 days.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final success = await _closeRoom(context);
            if (success && onSuccess != null) {
              onSuccess!();
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('CLOSE ROOM'),
        ),
      ],
    );
  }

  Future<bool> _closeRoom(BuildContext context) async {
    try {
      final chatService = ChatService();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Closing chat room...'),
          duration: Duration(seconds: 1),
        ),
      );

      final success = await chatService.closeChatRoom(roomId);

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Chat room closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to close chat room'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().split(': ').last}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}
