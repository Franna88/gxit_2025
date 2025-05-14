import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/popup_chat_room.dart';
import '../services/popup_chat_service.dart';
import '../screens/waiting_room_screen.dart';

class PopupChatSection extends StatelessWidget {
  const PopupChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final popupChatService = PopupChatService();
    
    // Initialize the service when widget is built
    // Use a future builder to handle initialization
    return FutureBuilder(
      future: popupChatService.initialize(),
      builder: (context, snapshot) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            border: Border(
              top: BorderSide(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
              bottom: BorderSide(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header with glowing text
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DAILY DISCUSSION TOPICS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.7,
                            shadows: [
                              Shadow(
                                color: AppColors.primaryBlue.withOpacity(0.7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.shuffle_rounded,
                            color: Colors.white70,
                            size: 10,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'RANDOM DAILY',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stream of scheduled popup chats
              SizedBox(
                height: 190,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<PopupChatRoom>>(
                        stream: popupChatService.getScheduledPopupChatRoomsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Error loading topics',
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Force refresh by creating a new instance of the service
                                      popupChatService.checkAndCreateDailyRoom();
                                      // This will reset the widget and try again
                                      (context as Element).markNeedsBuild();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
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
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Try to create a daily topic
                                      final created = await popupChatService.checkAndCreateDailyRoom();
                                      if (created && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('New discussion topic created!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        // Refresh the widget
                                        (context as Element).markNeedsBuild();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Generate Topic'),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
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
          ),
        );
      }
    );
  }

  Widget _buildPopupChatCard(BuildContext context, PopupChatRoom room) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final scheduledTime = dateFormat.format(room.scheduledTime);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.blueGrey.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Top decoration line in category color
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: _getCategoryColor(room.category),
              ),
            ),
            
            // Category badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(room.category).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  room.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 8, right: 40),
                    child: Text(
                      room.topic,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scheduledTime,
                        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 12,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Limited to ${room.maxCapacity} participants',
                        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 10,
                        color: Colors.amber[300],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildActionButton(context, room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, PopupChatRoom room) {
    final now = DateTime.now();
    final openWaitingRoomTime =
        room.openWaitingRoomTime ??
        room.scheduledTime.subtract(
          const Duration(minutes: PopupChatRoom.waitingRoomDurationMinutes),
        );

    // Calculate time until waiting room opens
    final timeUntilOpen = openWaitingRoomTime.difference(now);
    final popupChatService = PopupChatService();

    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      elevation: 2,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
      fontSize: 10,
    );

    // If waiting room is already open
    if (room.status == PopupChatStatus.waiting) {
      return Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            _navigateToWaitingRoom(context, room.id);
          },
          style: buttonStyle.copyWith(
            backgroundColor: MaterialStateProperty.all(AppColors.primaryBlue),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          child: Text(
            'JOIN WAITING ROOM',
            style: textStyle,
          ),
        ),
      );
    }

    // If waiting room not yet open
    final timeText = timeUntilOpen.inHours > 0
        ? 'OPENS IN ${timeUntilOpen.inHours}h ${timeUntilOpen.inMinutes % 60}m'
        : 'OPENS IN ${timeUntilOpen.inMinutes}m';

    return ElevatedButton(
      onPressed: null, // Disabled
      style: buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(Colors.grey[800]),
        foregroundColor: MaterialStateProperty.all(Colors.grey[400]),
      ),
      child: Text(timeText, style: textStyle),
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
  
  // Helper method to safely navigate and ensure back button works
  void _navigateToWaitingRoom(BuildContext context, String roomId) {
    final popupChatService = PopupChatService();
    
    // First join the waiting room
    popupChatService.joinWaitingRoom(roomId).then((success) {
      if (success) {
        // Get the room data to pass to the navigation
        popupChatService.getPopupChatRoomStream(roomId).first.then((room) {
          if (room != null && context.mounted) {
            // Navigate to the waiting room screen
            // Use pushReplacement instead of push to replace the current route
            // This prevents the issue where going back returns to this screen
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                builder: (context) => WaitingRoomScreen(
                  roomId: roomId,
                  topic: room.topic,
                ),
              ),
            );
          }
        });
      } else if (context.mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join waiting room.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}
