import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/popup_chat_room.dart';
import '../services/popup_chat_service.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final String topic;

  const WaitingRoomScreen({
    super.key,
    required this.roomId,
    required this.topic,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final PopupChatService _chatService = PopupChatService();
  
  @override
  void initState() {
    super.initState();
    
    // Listen for status changes and handle navigation
    _chatService.getPopupChatRoomStream(widget.roomId).listen((room) {
      if (room?.status == PopupChatStatus.active && mounted) {
        _handleChatStarted();
      }
    });
  }
  
  // Handle when chat starts - avoid using Future.delayed in build
  void _handleChatStarted() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The discussion has started! Joining now...'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate away from waiting room
      Navigator.of(context).pop();
      
      // Here you would navigate to the chat screen
      // This would depend on your app's navigation structure
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press - leave the waiting room
        await _chatService.leaveWaitingRoom(widget.roomId);
        return true; // Allow navigation back
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waiting Room'),
          backgroundColor: const Color(0xFF1A1A2E),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Leave waiting room when manually going back
              await _chatService.leaveWaitingRoom(widget.roomId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: StreamBuilder<PopupChatRoom?>(
          stream: _chatService.getPopupChatRoomStream(widget.roomId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading waiting room',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }
            
            final room = snapshot.data!;
            final waitingCount = room.waitingUsers.length;
            final maxCapacity = room.maxCapacity;

            // NOTE: Room active state is now handled in initState listener
            // to avoid rebuilding issues
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A2E),
                    AppColors.primaryPurple.withOpacity(0.7),
                    const Color(0xFF0A0A18),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 56,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.topic,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Waiting for discussion to start',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$waitingCount / $maxCapacity participants waiting',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            waitingCount >= maxCapacity
                                ? 'Waiting room is full'
                                : 'You will join automatically when the discussion starts',
                            style: TextStyle(
                              color: waitingCount >= maxCapacity
                                  ? Colors.amber
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _chatService.leaveWaitingRoom(widget.roomId);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Waiting Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 