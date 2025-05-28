import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/area_chat_room.dart';
import '../services/location_service.dart';
import 'horizontal_chat_room_card.dart';
import 'dart:math' as math;

class PrivateRoomsSection extends StatefulWidget {
  final Function(String roomId, String roomName) onRoomTap;

  const PrivateRoomsSection({
    Key? key, 
    required this.onRoomTap,
  }) : super(key: key);

  @override
  State<PrivateRoomsSection> createState() => _PrivateRoomsSectionState();
}

class _PrivateRoomsSectionState extends State<PrivateRoomsSection>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  List<AreaChatRoom> _privateChatRooms = [];
  Map<String, bool> _hasUnreadMessages = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadPrivateRooms();

    // Pulse animation for neon elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Public method to refresh data from parent
  Future<void> refresh() async {
    await _loadPrivateRooms();
  }

  // Generate and assign random unread message states
  void _generateUnreadStates(List<AreaChatRoom> rooms) {
    final random = math.Random();
    _hasUnreadMessages.clear();
    _unreadCounts.clear();

    for (final room in rooms) {
      final hasUnread = random.nextBool();
      _hasUnreadMessages[room.id] = hasUnread;
      _unreadCounts[room.id] = hasUnread ? random.nextInt(5) + 1 : 0;
    }
  }

  Future<void> _loadPrivateRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('PrivateRoomsSection: Starting to load private rooms...');
      final rooms = await _locationService.getPrivateChatRooms();
      debugPrint('PrivateRoomsSection: Received ${rooms.length} private rooms from LocationService');
      
      _generateUnreadStates(rooms);

      setState(() {
        _privateChatRooms = rooms;
        _isLoading = false;
      });
      
      debugPrint('PrivateRoomsSection: Updated state with ${_privateChatRooms.length} rooms');
    } catch (e) {
      debugPrint('PrivateRoomsSection: Error loading private rooms: $e');
      setState(() {
        _privateChatRooms = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _privateChatRooms.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _privateChatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _privateChatRooms[index];
                    final hasUnread = _hasUnreadMessages[room.id] ?? false;
                    final unreadCount = _unreadCounts[room.id] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: HorizontalChatRoomCard(
                        name: room.name,
                        lastMessage: room.lastMessage ?? 'No messages yet',
                        lastActivity: room.lastActivity ?? DateTime.now(),
                        memberCount: room.memberCount,
                        hasUnreadMessages: hasUnread,
                        unreadCount: unreadCount,
                        onTap: () => widget.onRoomTap(room.id, room.name),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.05),
            AppColors.primaryBlue.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No Private Rooms Available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create or join private chat rooms',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Debug refresh button
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('DEBUG: Manual refresh triggered');
                _loadPrivateRooms();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('DEBUG REFRESH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 