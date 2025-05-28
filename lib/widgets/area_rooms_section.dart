import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/area_chat_room.dart';
import '../services/location_service.dart';
import 'horizontal_chat_room_card.dart';
import 'dart:math' as math;

class AreaRoomsSection extends StatefulWidget {
  final Function(String roomId, String roomName) onRoomTap;

  const AreaRoomsSection({Key? key, required this.onRoomTap})
    : super(key: key);

  @override
  State<AreaRoomsSection> createState() => _AreaRoomsSectionState();
}

class _AreaRoomsSectionState extends State<AreaRoomsSection>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  List<AreaChatRoom> _areaChatRooms = [];
  Map<String, bool> _hasUnreadMessages = {};
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadAreaRooms();

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

  Future<void> _loadAreaRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rooms = await _locationService.getOfficialAreaChatRooms();
      _generateUnreadStates(rooms);

      setState(() {
        _areaChatRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading area rooms: $e');
      setState(() {
        _areaChatRooms = [];
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
          : _areaChatRooms.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _areaChatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _areaChatRooms[index];
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
            AppColors.primaryBlue.withOpacity(0.05),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No Area Rooms Available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for local chat rooms',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 