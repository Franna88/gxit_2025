import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/area_chat_room.dart';
import '../services/location_service.dart';
import 'horizontal_chat_room_card.dart';
import 'dart:math' as math;

class AreaChatRoomSection extends StatefulWidget {
  final Function(String) onRoomTap;

  const AreaChatRoomSection({Key? key, required this.onRoomTap})
    : super(key: key);

  @override
  State<AreaChatRoomSection> createState() => _AreaChatRoomSectionState();
}

class _AreaChatRoomSectionState extends State<AreaChatRoomSection>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  bool _showOfficialRooms = true;
  List<AreaChatRoom> _areaChatRooms = [];
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

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_showOfficialRooms) {
        final rooms = await _locationService.getOfficialAreaChatRooms();
        setState(() {
          _areaChatRooms = rooms;
          _isLoading = false;
        });
      } else {
        // In a real app, this would load user-created chat rooms
        // For demo, we'll just use the sample rooms with different IDs
        final rooms = await _locationService.getNearbyAreaChatRooms();
        final random = math.Random();
        final userRooms =
            rooms.map((room) {
              return AreaChatRoom(
                id: 'user-${random.nextInt(10000)}',
                name: 'User Group: ${room.name}',
                memberIds: [],
                areaName: room.areaName,
                location: room.location,
                radius: room.radius,
                description: 'User created group for ${room.areaName}',
                isOfficial: false,
                createdAt: DateTime.now().subtract(
                  Duration(days: random.nextInt(30)),
                ),
                memberCount: random.nextInt(30) + 3,
              );
            }).toList();

        setState(() {
          _areaChatRooms = userRooms;
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
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Text(
                    'CHAT ROOMS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryBlue.withOpacity(
                            0.7 * _pulseAnimation.value,
                          ),
                          blurRadius: 8 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
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
                    color:
                        _showOfficialRooms
                            ? AppColors.primaryBlue.withOpacity(0.2)
                            : AppColors.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _showOfficialRooms
                              ? AppColors.primaryBlue.withOpacity(0.5)
                              : AppColors.primaryPurple.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _showOfficialRooms
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
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _areaChatRooms.length,
                    itemBuilder: (context, index) {
                      final room = _areaChatRooms[index];
                      return HorizontalChatRoomCard(
                        name: room.name,
                        lastMessage:
                            room.description ??
                            'Join the conversation in ${room.areaName}',
                        lastActivity: room.createdAt ?? DateTime.now(),
                        memberCount: room.memberCount,
                        hasUnreadMessages: math.Random().nextBool(),
                        unreadCount: math.Random().nextInt(5),
                        onTap: () => widget.onRoomTap(room.name),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
