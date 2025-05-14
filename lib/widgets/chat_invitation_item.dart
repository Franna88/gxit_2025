import 'package:flutter/material.dart';
import '../models/chat_invitation.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';

class ChatInvitationItem extends StatefulWidget {
  final ChatInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ChatInvitationItem({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<ChatInvitationItem> createState() => _ChatInvitationItemState();
}

class _ChatInvitationItemState extends State<ChatInvitationItem> {
  bool _isLoading = false;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Invitation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ve been invited to join "${widget.invitation.roomName}"',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: _handleDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _chatService.acceptChatInvitation(
        widget.invitation.id,
      );

      if (success && mounted) {
        // Navigate to the chat room
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  contactName: widget.invitation.roomName,
                  chatRoomId: widget.invitation.roomId,
                ),
          ),
        );

        // Call the callback
        widget.onAccept();
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDecline() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _chatService.declineChatInvitation(
        widget.invitation.id,
      );

      if (success && mounted) {
        // Call the callback
        widget.onDecline();
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
