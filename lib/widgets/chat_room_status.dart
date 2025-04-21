import 'package:flutter/material.dart';
import '../models/chat_room.dart';

class ChatRoomStatus extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback? onCloseRoom;
  final VoidCallback? onInviteUsers;
  final bool isCreator;

  const ChatRoomStatus({
    super.key,
    required this.room,
    this.onCloseRoom,
    this.onInviteUsers,
    this.isCreator = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(theme).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor(theme), size: 16),
              const SizedBox(width: 4),
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(theme),
                ),
              ),
            ],
          ),
        ),

        // Expiration info if room is closed
        if (room.isClosed && room.expiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'This room will be deleted on ${_formatDate(room.expiresAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Room actions for creator
        if (isCreator && !room.isClosed)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (onInviteUsers != null)
                  OutlinedButton.icon(
                    onPressed: onInviteUsers,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Invite'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (onInviteUsers != null && onCloseRoom != null)
                  const SizedBox(width: 8),
                if (onCloseRoom != null)
                  OutlinedButton.icon(
                    onPressed: onCloseRoom,
                    icon: const Icon(Icons.meeting_room_outlined, size: 16),
                    label: const Text('Close Room'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getStatusIcon() {
    if (room.isClosed) {
      return Icons.meeting_room_outlined;
    }

    return Icons.meeting_room;
  }

  String _getStatusText() {
    if (room.isClosed) {
      return 'Room Closed';
    }

    return 'Active Room';
  }

  Color _getStatusColor(ThemeData theme) {
    if (room.isClosed) {
      return theme.colorScheme.error;
    }

    return theme.colorScheme.primary;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }
}
