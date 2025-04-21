import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/popup_chat_room.dart';
import '../services/popup_chat_service.dart';

class PopupChatSection extends StatelessWidget {
  const PopupChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final popupChatService = PopupChatService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with glowing text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY DISCUSSION TOPICS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryBlue.withOpacity(0.7),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'RANDOM DAILY',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stream of scheduled popup chats
        SizedBox(
          height: 160,
          child: StreamBuilder<List<PopupChatRoom>>(
            stream: popupChatService.getScheduledPopupChatRoomsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading topics',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                );
              }

              final rooms = snapshot.data ?? [];
              if (rooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.grey[400],
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming discussion topics yet',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back soon!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return _buildPopupChatCard(context, room);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopupChatCard(BuildContext context, PopupChatRoom room) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final scheduledTime = dateFormat.format(room.scheduledTime);

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.blueGrey.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Category badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(room.category).withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  room.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.topic,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scheduledTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Limited to ${room.maxCapacity} participants',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildActionButton(room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(PopupChatRoom room) {
    final now = DateTime.now();
    final openWaitingRoomTime =
        room.openWaitingRoomTime ??
        room.scheduledTime.subtract(
          const Duration(minutes: PopupChatRoom.waitingRoomDurationMinutes),
        );

    // Calculate time until waiting room opens
    final timeUntilOpen = openWaitingRoomTime.difference(now);
    final popupChatService = PopupChatService();

    // If waiting room is already open
    if (room.status == PopupChatStatus.waiting) {
      return ElevatedButton(
        onPressed: () {
          popupChatService.joinWaitingRoom(room.id);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          minimumSize: const Size(double.infinity, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text('JOIN WAITING ROOM'),
      );
    }

    // If waiting room not yet open
    return ElevatedButton(
      onPressed: null, // Disabled
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        disabledBackgroundColor: Colors.grey[800],
        disabledForegroundColor: Colors.grey[400],
        minimumSize: const Size(double.infinity, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        timeUntilOpen.inHours > 0
            ? 'OPENS IN ${timeUntilOpen.inHours}h ${timeUntilOpen.inMinutes % 60}m'
            : 'OPENS IN ${timeUntilOpen.inMinutes}m',
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'society':
        return Colors.orange;
      case 'philosophy':
        return Colors.teal;
      case 'controversial':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}
