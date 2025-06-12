import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/area_chat_room.dart';
import '../services/location_service.dart';
import 'horizontal_chat_room_card.dart';
import 'dart:math' as math;

class AreaChatRoomSection extends StatefulWidget {
  final Function(String) onRoomTap;

  const AreaChatRoomSection({super.key, required this.onRoomTap});

  @override
  State<AreaChatRoomSection> createState() => _AreaChatRoomSectionState();
}

class _AreaChatRoomSectionState extends State<AreaChatRoomSection>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  bool _showOfficialRooms = true;
  List<AreaChatRoom> _areaChatRooms = [];
  final Map<String, bool> _hasUnreadMessages = {};
  final Map<String, int> _unreadCounts = {};
  bool _isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();

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

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_showOfficialRooms) {
        final rooms = await _locationService.getOfficialAreaChatRooms();
        _generateUnreadStates(rooms);

        setState(() {
          _areaChatRooms = rooms;
          _isLoading = false;
        });
      } else {
        // Load private user-created chat rooms
        final rooms = await _locationService.getPrivateChatRooms();
        _generateUnreadStates(rooms);

        setState(() {
          _areaChatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
      setState(() {
        _areaChatRooms = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section header with toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Section Title with neon effect
              Text(
                'CHAT ROOMS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryBlue.withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),

              // Toggle Switch
              InkWell(
                onTap: () {
                  setState(() {
                    _showOfficialRooms = !_showOfficialRooms;
                  });
                  _loadChatRooms();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showOfficialRooms
                        ? AppColors.primaryBlue.withOpacity(0.2)
                        : AppColors.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showOfficialRooms
                          ? AppColors.primaryBlue.withOpacity(0.5)
                          : AppColors.primaryPurple.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _showOfficialRooms
                            ? AppColors.primaryBlue.withOpacity(0.3)
                            : AppColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _showOfficialRooms ? 'AREA ROOMS' : 'PRIVATE ROOMS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _showOfficialRooms ? Icons.public : Icons.lock,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Room List
        SizedBox(
          height: 160,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _areaChatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _areaChatRooms[index];
                    final hasUnread = _hasUnreadMessages[room.id] ?? false;
                    final unreadCount = _unreadCounts[room.id] ?? 0;

                    return HorizontalChatRoomCard(
                      name: room.name,
                      lastMessage: room.description ??
                          'Join the conversation in ${room.areaName}',
                      lastActivity: room.createdAt ?? DateTime.now(),
                      memberCount: room.memberCount,
                      hasUnreadMessages: hasUnread,
                      unreadCount: unreadCount,
                      onTap: () => widget.onRoomTap(room.name),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
