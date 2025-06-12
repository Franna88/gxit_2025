import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../widgets/chat_room_card.dart';
import '../services/chat_service.dart';
import '../services/location_service.dart';
import '../models/area_chat_room.dart';
import '../models/chat_room.dart';
import '../widgets/not_enough_tokens_dialog.dart';
import '../widgets/token_balance.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  final bool focusOnPrivateRooms;

  const ChatsScreen({super.key, this.focusOnPrivateRooms = false});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Services
  final ChatService chatService = ChatService();
  // Location service to get area chat rooms
  final _locationService = LocationService();
  List<AreaChatRoom> _areaChatRooms = [];
  List<AreaChatRoom> _privateChatRooms = [];
  bool _isLoading = true;
  bool _hasError = false; // Add error state tracking
  String? _errorMessage; // Add error message tracking

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<AreaChatRoom> _filteredAreaChatRooms = [];
  List<AreaChatRoom> _filteredPrivateChatRooms = [];
  final FocusNode _searchFocusNode = FocusNode();

  // Animation controllers for each card's hover effect
  final Map<int, AnimationController> _hoverControllers = {};
  bool _isHovering = false;
  int _hoveredIndex = -1;

  // Scroll controller for auto-scrolling to private rooms
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _privateRoomsKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Load chat rooms with retry logic
    _loadChatRoomsWithRetry();

    // Pulse animation for neon elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize hover animations for each card
    for (int i = 0; i < 12; i++) {
      _hoverControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }

    // Set up search text listener
    _searchController.addListener(_performSearch);
  }

  // Add retry logic for loading chat rooms
  Future<void> _loadChatRoomsWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        await _loadChatRooms();
        return; // Success, exit the retry loop
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('Retry $retryCount after error: $e');
          await Future.delayed(retryDelay);
        }
      }
    }

    // If we get here, all retries failed
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage =
          'Unable to load chats after several attempts. Please check your connection.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _loadChatRoomsWithRetry();
            },
          ),
        ),
      );
    });
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();

      // Check if this looks like a room ID (typically a long alphanumeric string)
      // For example: g429P4B82sWC3N9snYaX
      if (_searchQuery.length >= 20 &&
          _searchQuery.contains(RegExp(r'^[a-zA-Z0-9]+$'))) {
        // Search for room by ID
        _searchRoomById(_searchQuery);
        return;
      }

      _filterRooms();
    });
  }

  void _filterRooms() {
    if (_searchQuery.isEmpty) {
      _filteredAreaChatRooms = List.from(_areaChatRooms);
      _filteredPrivateChatRooms = List.from(_privateChatRooms);
    } else {
      final lowerCaseQuery = _searchQuery.toLowerCase();

      _filteredAreaChatRooms = _areaChatRooms
          .where((room) =>
              room.name.toLowerCase().contains(lowerCaseQuery) ||
              (room.description?.toLowerCase().contains(lowerCaseQuery) ??
                  false) ||
              room.areaName.toLowerCase().contains(lowerCaseQuery) ||
              room.id.contains(_searchQuery)) // Case-sensitive for room ID
          .toList();

      _filteredPrivateChatRooms = _privateChatRooms
          .where((room) =>
              room.name.toLowerCase().contains(lowerCaseQuery) ||
              (room.description?.toLowerCase().contains(lowerCaseQuery) ??
                  false) ||
              room.areaName.toLowerCase().contains(lowerCaseQuery) ||
              room.id.contains(_searchQuery)) // Case-sensitive for room ID
          .toList();
    }
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      final userId = chatService.currentUserId;
      debugPrint('Loading chats for user: $userId');

      if (userId == null || userId.isEmpty) {
        debugPrint('User not authenticated');
        throw Exception('User not authenticated');
      }

      // Load area chat rooms
      debugPrint('Loading official area chat rooms...');
      final officialRooms = await _locationService.getOfficialAreaChatRooms();
      debugPrint('Loaded ${officialRooms.length} official rooms');
      if (!mounted) return;

      debugPrint('Loading private chat rooms...');
      final privateRooms = await _locationService.getPrivateChatRooms();
      debugPrint('Loaded ${privateRooms.length} private rooms');
      if (!mounted) return;

      // Load regular chat rooms created with createChatRoom
      debugPrint('Loading user chat rooms...');
      final userChatRooms =
          await chatService.getUserChatRoomsStream(userId).first;
      debugPrint('Loaded ${userChatRooms.length} user rooms');
      if (!mounted) return;

      // Filter out direct messages - they should only appear in Contacts > Active Chats
      final nonDirectMessageRooms =
          userChatRooms.where((room) => !room.isDirectMessage);
      debugPrint(
          'Found ${nonDirectMessageRooms.length} non-direct message rooms');

      // Convert regular ChatRoom objects to AreaChatRoom for UI display
      final publicRegularRooms = nonDirectMessageRooms
          .where((room) => room.isPublic)
          .map((room) => AreaChatRoom(
                id: room.id,
                name: room.name,
                areaName: "User Room",
                creatorId: room.creatorId ?? '',
                createdAt: room.createdAt,
                isPublic: room.isPublic,
                memberCount: room.memberCount,
                memberIds: room.memberIds,
                location: const GeoPoint(0, 0),
                radius: 0,
                lastMessage: room.lastMessage,
                lastActivity: room.lastActivity,
                isOfficial: false,
                isDirectMessage: room.isDirectMessage,
                participantIds: room.participantIds,
              ))
          .toList();

      final privateRegularRooms = nonDirectMessageRooms
          .where((room) => !room.isPublic)
          .map((room) => AreaChatRoom(
                id: room.id,
                name: room.name,
                areaName: "Private Room",
                creatorId: room.creatorId ?? '',
                createdAt: room.createdAt,
                isPublic: room.isPublic,
                memberCount: room.memberCount,
                memberIds: room.memberIds,
                location: const GeoPoint(0, 0),
                radius: 0,
                lastMessage: room.lastMessage,
                lastActivity: room.lastActivity,
                isOfficial: false,
                isDirectMessage: room.isDirectMessage,
                participantIds: room.participantIds,
              ))
          .toList();

      setState(() {
        // Filter out any direct messages from area rooms as well (just to be safe)
        _areaChatRooms =
            officialRooms.where((room) => !room.isDirectMessage).toList();
        _privateChatRooms =
            privateRooms.where((room) => !room.isDirectMessage).toList();

        // Add regular rooms while avoiding duplicates
        for (final room in publicRegularRooms) {
          if (!_areaChatRooms.any((r) => r.id == room.id)) {
            _areaChatRooms.add(room);
          }
        }

        for (final room in privateRegularRooms) {
          if (!_privateChatRooms.any((r) => r.id == room.id)) {
            _privateChatRooms.add(room);
          }
        }

        // Sort rooms by creation date (newest first)
        _areaChatRooms.sort((a, b) {
          if (b.createdAt == null) return 0;
          return b.createdAt.compareTo(a.createdAt);
        });

        _privateChatRooms.sort((a, b) {
          if (b.createdAt == null) return 0;
          return b.createdAt.compareTo(a.createdAt);
        });

        _isLoading = false;
        _filterRooms(); // Apply any existing search filter to the newly loaded rooms

        // Auto-scroll to private rooms if requested
        if (widget.focusOnPrivateRooms) {
          _scrollToPrivateRooms();
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading chat rooms: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().contains('not authenticated')
            ? 'Please sign in to view chats'
            : 'Error loading chats: ${e.toString()}. Please check your connection and try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _loadChatRoomsWithRetry();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (var controller in _hoverControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToChat(BuildContext context, String name, String roomId) {
    // Use pushReplacement if coming from a dialog or another temporary screen
    // This prevents the back button from re-entering the chat room
    final currentRoute = ModalRoute.of(context);
    final isDialog = currentRoute?.settings.name == null ||
        currentRoute!.settings.name!.isEmpty;

    if (isDialog) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(contactName: name, chatRoomId: roomId),
        ),
      ).then((_) {
        // Refresh room list when returning from chat screen
        if (mounted) {
          _loadChatRooms();
        }
      });
    } else {
      // Standard navigation for normal screens
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(contactName: name, chatRoomId: roomId),
        ),
      ).then((_) {
        // Refresh room list when returning from chat screen
        if (mounted) {
          _loadChatRooms();
        }
      });
    }
  }

  void _onHover(int index, bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      _hoveredIndex = isHovering ? index : -1;
    });

    if (isHovering) {
      _hoverControllers[index]?.forward();
    } else {
      _hoverControllers[index]?.reverse();
    }
  }

  String _getTargetAudience(String name, String areaName) {
    if (name.contains("Main Beach") || name.contains("Supertubes")) {
      return 'For Surfers & Beach Lovers';
    } else if (name.contains("Marina")) {
      return 'For Marina Residents & Visitors';
    } else if (name.contains("Francis")) {
      return 'For St Francis Bay Locals';
    } else if (name.contains("Photography") || name.contains("Photo")) {
      return 'For Visual Artists & Photographers';
    } else if (name.contains("Surf") || name.contains("Beach")) {
      return 'For Surfers & Beach Enthusiasts';
    } else if (name.contains("Restaurant") || name.contains("Food")) {
      return 'For Foodies & Culinary Enthusiasts';
    } else if (name.contains("Fishing")) {
      return 'For Fishing Enthusiasts';
    } else if (name.contains("Golf")) {
      return 'For Golf Enthusiasts';
    } else if (name.contains("Extreme")) {
      return 'For Adventure Seekers';
    } else if (name.contains("Cleanup") || name.contains("Environment")) {
      return 'For Environmental Activists';
    } else {
      return 'Community Space in $areaName';
    }
  }

  // Get color based on chat room name
  Color _getRoomColor(String name) {
    if (name.contains("Main Beach") ||
        name.contains("Surf") ||
        name.contains("Beach")) {
      return AppColors.primaryBlue;
    } else if (name.contains("Marina") || name.contains("St Francis")) {
      return AppColors.primaryPurple;
    } else if (name.contains("Aston") ||
        name.contains("Paradise") ||
        name.contains("Cleanup")) {
      return AppColors.primaryGreen;
    } else if (name.contains("Photography") || name.contains("Extreme")) {
      return AppColors.primaryOrange;
    } else if (name.contains("Restaurant") || name.contains("Fish")) {
      return AppColors.primaryYellow;
    } else {
      return AppColors.primaryBlue; // Default
    }
  }

  // Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _performSearch();
      }
    });
  }

  // Search for a room by ID
  Future<void> _searchRoomById(String roomId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to find in chatRooms collection
      final room = await chatService.getChatRoomById(roomId);
      if (room != null) {
        setState(() {
          _isLoading = false;
        });

        // Check if user is already a member
        if (room.memberIds.contains(chatService.currentUserId)) {
          // Navigate to chat if user is already a member
          _navigateToChat(context, room.name, room.id);
          return;
        } else if (room.isPublic) {
          // For public rooms, show join dialog
          _showRoomFoundDialog(
            context: context,
            roomName: room.name,
            roomId: room.id,
            isPublic: true,
            isAreaRoom: false,
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This room is private and you are not a member'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // If not found, try in areaChatRooms collection
      final areaRoom = await _locationService.getAreaChatRoomById(roomId);
      if (areaRoom != null) {
        setState(() {
          _isLoading = false;
        });

        // Check if user is already a member
        if (areaRoom.memberIds.contains(chatService.currentUserId)) {
          // Navigate to chat if user is already a member
          _navigateToChat(context, areaRoom.name, areaRoom.id);
          return;
        } else if (areaRoom.isPublic) {
          // For public rooms, show join dialog
          _showRoomFoundDialog(
            context: context,
            roomName: areaRoom.name,
            roomId: areaRoom.id,
            isPublic: true,
            isAreaRoom: true,
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This room is private and you are not a member'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Not found in either collection
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat room not found with that ID'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by name, area or room ID...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      _filterRooms();
                    },
                  ),
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: AppColors.primaryBlue,
                autofocus: true,
              )
            : const Text('Chat Rooms'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: _isSearching
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _toggleSearch,
              )
            : null,
        actions: [
          // Search icon
          IconButton(
            icon: Icon(_isSearching ? Icons.search_off : Icons.search),
            tooltip: _isSearching ? 'Cancel search' : 'Search rooms',
            onPressed: _toggleSearch,
          ),
          // Add Join Room button if not searching
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.login_rounded),
              tooltip: 'Join Room by ID',
              onPressed: () => _showJoinRoomDialog(context),
            ),
          // Add token balance in the AppBar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TokenBalance(isCompact: true, showLabel: false),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1A),
              AppColors.primaryPurple.withOpacity(0.8),
              const Color(0xFF0A0A18),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(child: CustomPaint(painter: GridPainter())),

            // Main content
            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading chats...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage ?? 'Error loading chats',
                                style: TextStyle(
                                  color: Colors.red[300],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _loadChatRoomsWithRetry,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            // Only show the neon app bar if not searching
                            if (!_isSearching)
                              SliverAppBar(
                                floating: true,
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                title: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Text(
                                      'JEFFREYS BAY CHAT ROOMS',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2.0,
                                        shadows: [
                                          Shadow(
                                            color: AppColors.primaryBlue
                                                .withOpacity(
                                              0.7 * _pulseAnimation.value,
                                            ),
                                            blurRadius:
                                                10 * _pulseAnimation.value,
                                          ),
                                          Shadow(
                                            color: AppColors.primaryPurple
                                                .withOpacity(
                                              0.5 * _pulseAnimation.value,
                                            ),
                                            blurRadius:
                                                15 * _pulseAnimation.value,
                                            offset: const Offset(2, 1),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                actions: [
                                  _buildNeonIconButton(Icons.search,
                                      onTap: _toggleSearch),
                                  _buildNeonIconButton(Icons.add,
                                      onTap: () =>
                                          _showCreateRoomDialog(context)),
                                ],
                              ),

                            // Show search results count when searching
                            if (_isSearching && _searchQuery.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Found ${_filteredAreaChatRooms.length + _filteredPrivateChatRooms.length} results for "$_searchQuery"',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                            // Search hint when search is active but empty
                            if (_isSearching && _searchQuery.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Search Tips:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '• Enter room name or keywords\n'
                                        '• Search by area name\n'
                                        '• Paste a room ID to find a specific room',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Section header for Area Chat Rooms - only show if there are results or not searching
                            if (_filteredAreaChatRooms.isNotEmpty ||
                                _searchQuery.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'AREA CHAT ROOMS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color:
                                              AppColors.primaryBlue.withOpacity(
                                            0.7,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Area Chat Rooms Grid - use filtered rooms
                            if (_filteredAreaChatRooms.isNotEmpty ||
                                (_searchQuery.isEmpty && !_isSearching))
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      // Only show create new room tile when not searching
                                      if (!_isSearching &&
                                          index >=
                                              _filteredAreaChatRooms.length) {
                                        return _buildCreateNewRoomTile();
                                      }

                                      if (index >=
                                          _filteredAreaChatRooms.length) {
                                        return null;
                                      }

                                      final room =
                                          _filteredAreaChatRooms[index];
                                      final color = _getRoomColor(room.name);

                                      return _buildRoomTileFromRoom(
                                        index,
                                        room,
                                        color,
                                      );
                                    },
                                    childCount: _isSearching
                                        ? _filteredAreaChatRooms.length
                                        : _filteredAreaChatRooms.length +
                                            1, // +1 for "Create New" tile when not searching
                                  ),
                                ),
                              ),

                            // No results message for area rooms when searching
                            if (_isSearching &&
                                _searchQuery.isNotEmpty &&
                                _filteredAreaChatRooms.isEmpty &&
                                _filteredPrivateChatRooms.isEmpty)
                              SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 48,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No chat rooms found matching "$_searchQuery"',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          icon: Icon(Icons.add, size: 16),
                                          label:
                                              Text('Create a new room instead'),
                                          onPressed: () {
                                            _toggleSearch();
                                            _showCreateRoomDialog(context);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppColors.primaryBlue,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Section header for Private Chat Rooms - only show if there are results or not searching
                            if (_filteredPrivateChatRooms.isNotEmpty ||
                                (_searchQuery.isEmpty && !_isSearching))
                              SliverToBoxAdapter(
                                key: _privateRoomsKey,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  child: Text(
                                    'PRIVATE CHAT ROOMS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: AppColors.primaryPurple
                                              .withOpacity(0.7),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Private Chat Rooms Grid - use filtered rooms
                            if (_filteredPrivateChatRooms.isNotEmpty ||
                                (_searchQuery.isEmpty && !_isSearching))
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    if (index >=
                                        _filteredPrivateChatRooms.length) {
                                      return null;
                                    }

                                    final room =
                                        _filteredPrivateChatRooms[index];
                                    final color = _getRoomColor(room.name);

                                    return _buildRoomTileFromRoom(
                                      index + _filteredAreaChatRooms.length,
                                      room,
                                      color,
                                    );
                                  },
                                      childCount:
                                          _filteredPrivateChatRooms.length),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSearching ? null : _buildFloatingActionButton(),
    );
  }

  Widget _buildRoomTileFromRoom(
    int index,
    AreaChatRoom room,
    Color accentColor,
  ) {
    final random = DateTime.now().millisecond % 2 == 0;
    final hasUnread = random;
    final unreadCount = hasUnread ? ((DateTime.now().second % 5) + 1) : 0;
    final targetAudience = _getTargetAudience(room.name, room.areaName);

    // Generate a plausible last message
    String lastMessage = '';
    if (room.name.contains('Surf')) {
      lastMessage = 'The waves look amazing today! 🌊';
    } else if (room.name.contains('Restaurant')) {
      lastMessage = 'Has anyone tried the new seafood place?';
    } else if (room.name.contains('Marina')) {
      lastMessage = 'Meeting at the clubhouse at 6pm';
    } else if (room.name.contains('Fish')) {
      lastMessage = 'Caught a 5kg yellowtail today! 🐟';
    } else if (room.name.contains('Beach')) {
      lastMessage = 'Beach day tomorrow if weather holds!';
    } else if (room.name.contains('Golf')) {
      lastMessage = 'Anyone up for a round this weekend?';
    } else if (room.name.contains('Photography')) {
      lastMessage = 'Sunset photos from Paradise Beach 📸';
    } else {
      lastMessage = 'Join the conversation in ${room.areaName}';
    }

    return _buildRoomTile(
      index,
      room.name,
      lastMessage,
      room.createdAt ?? DateTime.now().subtract(const Duration(hours: 5)),
      room.memberCount,
      hasUnread,
      unreadCount,
      accentColor,
      targetAudience: targetAudience,
      roomId: room.id,
    );
  }

  Widget _buildRoomTile(
    int index,
    String roomName,
    String lastMessage,
    DateTime lastActivity,
    int memberCount,
    bool hasUnreadMessages,
    int unreadCount,
    Color accentColor, {
    String? targetAudience,
    required String roomId,
  }) {
    return MouseRegion(
      onEnter: (_) => _onHover(index, true),
      onExit: (_) => _onHover(index, false),
      child: AnimatedBuilder(
        animation: _hoverControllers[index] ?? _pulseController,
        builder: (context, child) {
          final hoverValue = _hoverControllers[index]?.value ?? 0.0;

          return GestureDetector(
            onTap: () => _navigateToChat(context, roomName, roomId),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.2 + (0.1 * hoverValue)),
                    const Color(0xFF1A1A2E),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.3 + (0.3 * hoverValue)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2 + (0.3 * hoverValue)),
                    blurRadius: 10 * (1 + hoverValue),
                    spreadRadius: 1 * (1 + hoverValue),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room name
                        Row(
                          children: [
                            Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                color: hasUnreadMessages
                                    ? AppColors.primaryGreen
                                    : accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (hasUnreadMessages
                                            ? AppColors.primaryGreen
                                            : accentColor)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                roomName,
                                style: TextStyle(
                                  fontSize: 16 + (2 * hoverValue),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: accentColor.withOpacity(0.7),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Target audience
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(
                              0.15 + (0.05 * hoverValue),
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: accentColor.withOpacity(
                                0.2 + (0.1 * hoverValue),
                              ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            targetAudience ?? _getTargetAudience(roomName, ''),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Message preview
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade300,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Bottom info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Member count
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  memberCount.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),

                            // Time or unread count
                            hasUnreadMessages && unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 5,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _getTimeText(lastActivity),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Share button (top-right)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: hoverValue > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: Icon(
                            Icons.share,
                            color: accentColor.withOpacity(0.9),
                            size: 16,
                          ),
                          tooltip: 'Share Room ID',
                          splashRadius: 20,
                          onPressed: () =>
                              _showShareRoomIdDialog(context, roomName, roomId),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeText(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  Widget _buildCreateNewRoomTile() {
    return GestureDetector(
      onTap: () {
        _showCreateRoomDialog(context);
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.2),
                  Colors.black.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(
                  0.3 * _pulseAnimation.value,
                ),
                width: 1.5,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(
                    0.2 * _pulseAnimation.value,
                  ),
                  blurRadius: 8 * _pulseAnimation.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(
                            0.3 * _pulseAnimation.value,
                          ),
                          blurRadius: 10 * _pulseAnimation.value,
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(
                          0.5 * _pulseAnimation.value,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 30,
                      color: AppColors.primaryBlue.withOpacity(
                        0.5 + (0.5 * _pulseAnimation.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CREATE NEW ROOM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue.withOpacity(
                        0.7 + (0.3 * _pulseAnimation.value),
                      ),
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryBlue.withOpacity(
                            0.5 * _pulseAnimation.value,
                          ),
                          blurRadius: 5 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryOrange.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.token,
                          size: 12,
                          color: AppColors.primaryOrange.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ChatRoom.createRoomTokenCost} TOKENS',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryOrange.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    final TextEditingController roomNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool isPublic = true;
    final chatService = ChatService();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppColors.primaryBlue,
              width: 1,
            ),
          ),
          title: const Text(
            'Create New Chat Room',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Public Room: ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Switch(
                      value: isPublic,
                      onChanged: (value) {
                        setState(() {
                          isPublic = value;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: Creating a room costs 100 tokens',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final roomName = roomNameController.text.trim();
                if (roomName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room name cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Check if user has enough tokens
                try {
                  final tokenBalance = await chatService.getUserTokenBalance();

                  if (tokenBalance < ChatRoom.createRoomTokenCost) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      NotEnoughTokensDialog.show(
                        context: context,
                        requiredTokens: ChatRoom.createRoomTokenCost,
                        currentTokens: tokenBalance,
                        onBuyTokens: () {
                          // Handle token purchase
                        },
                      );
                    }
                    return;
                  }

                  // Create new room
                  final roomId = await chatService.createChatRoom(
                    name: roomName,
                    memberIds: [chatService.currentUserId!],
                    isPublic: isPublic,
                    isDirectMessage:
                        false, // This creates a regular chat room (public or private), not a direct message
                  );

                  if (roomId != null && context.mounted) {
                    Navigator.pop(context);

                    // Manually add new room to local state for immediate UI update
                    _addNewRoomToLocalState(
                      roomId,
                      roomName,
                      descriptionController.text.trim(),
                      isPublic,
                    );

                    // Show success dialog
                    _showRoomCreatedDialog(context, roomName, roomId);

                    // Also refresh rooms from the server
                    if (mounted) {
                      _loadChatRooms();
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create chat room'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString().split(': ').last}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('CREATE'),
            ),
          ],
        ),
      ),
    );
  }

  // Show success dialog after creating a room
  void _showRoomCreatedDialog(
    BuildContext context,
    String roomName,
    String roomId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryGreen, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Success!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your chat room "$roomName" has been created successfully!',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Room ID:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      roomId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.white54,
                      size: 16,
                    ),
                    onPressed: () {
                      // Copy room ID to clipboard
                      Clipboard.setData(ClipboardData(text: roomId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room ID copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Force refresh the chat rooms list
              _loadChatRooms();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to the chat room
              _navigateToChat(context, roomName, roomId);
              // Force refresh the chat rooms list when the user comes back
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _loadChatRooms();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('OPEN ROOM'),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonIconButton(IconData icon, {VoidCallback? onTap}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(
                  0.3 * _pulseAnimation.value,
                ),
                blurRadius: 8 * _pulseAnimation.value,
                spreadRadius: 1 * _pulseAnimation.value,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Find Room Button
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'findRoomBtn',
                onPressed: _showFindRoomDialog,
                backgroundColor: AppColors.primaryPurple,
                mini: true,
                child: const Icon(Icons.search),
              ),
            ),

            // Create Room Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(
                      0.4 * _pulseAnimation.value,
                    ),
                    blurRadius: 15 * _pulseAnimation.value,
                    spreadRadius: 2 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'createRoomBtn',
                onPressed: () => _showCreateRoomDialog(context),
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to join a room by ID
  void _showJoinRoomDialog(BuildContext context) {
    final TextEditingController roomIdController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing when loading
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryBlue, width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.login_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'Join Chat Room',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the ID of the chat room you want to join',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomIdController,
                decoration: InputDecoration(
                  labelText: 'Room ID',
                  hintText: 'Enter room ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryBlue),
                  ),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.tag, color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: AppColors.primaryBlue,
                enabled: !isLoading,
              ),

              // Show loading indicator when processing
              if (isLoading)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Looking for room...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final roomId = roomIdController.text.trim();
                      if (roomId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room ID cannot be empty'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Set loading state
                      setState(() {
                        isLoading = true;
                      });

                      // Try joining the room
                      try {
                        // Check if room exists first
                        final room =
                            await chatService.getChatRoomStream(roomId).first;

                        if (room == null) {
                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Room does not exist'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        // Join the room
                        final joined = await chatService.joinChatRoom(roomId);

                        if (context.mounted) {
                          // Close the dialog
                          Navigator.pop(dialogContext);

                          // Convert ChatRoom to AreaChatRoom for UI display
                          final areaChatRoom = AreaChatRoom(
                            id: room.id,
                            name: room.name,
                            areaName: "Joined Room",
                            creatorId: room.creatorId ?? '',
                            createdAt: room.createdAt,
                            isPublic: room.isPublic,
                            memberCount: room.memberCount +
                                1, // Include the user who just joined
                            memberIds: [
                              ...room.memberIds,
                              chatService.currentUserId!
                            ],
                            location: const GeoPoint(0, 0),
                            radius: 0,
                          );

                          // Add to local state immediately
                          _addRoomToLocalStateAfterJoining(areaChatRoom);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully joined ${room.name}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'OPEN',
                                textColor: Colors.white,
                                onPressed: () {
                                  // Navigate to the chat room
                                  _navigateToChat(context, room.name, roomId);
                                },
                              ),
                            ),
                          );

                          // Refresh rooms
                          if (mounted) {
                            _loadChatRooms();
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString().split(': ').last}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.4),
              ),
              child: const Text('JOIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewRoomToLocalState(
    String roomId,
    String roomName,
    String description,
    bool isPublic,
  ) {
    // Check if room already exists in local state to avoid duplicates
    final isAreaRoomExists = _areaChatRooms.any((r) => r.id == roomId);
    final isPrivateRoomExists = _privateChatRooms.any((r) => r.id == roomId);

    if (isAreaRoomExists || isPrivateRoomExists) {
      return; // Skip if already in the list
    }

    setState(() {
      if (isPublic) {
        _areaChatRooms = [
          AreaChatRoom(
            id: roomId,
            name: roomName,
            areaName: 'My Chat Room',
            description: description.isNotEmpty ? description : null,
            creatorId: chatService.currentUserId!,
            createdAt: DateTime.now(),
            isPublic: isPublic,
            memberCount: 1,
            memberIds: [chatService.currentUserId!],
            location: const GeoPoint(0, 0),
            radius: 0,
          ),
          ..._areaChatRooms,
        ];
      } else {
        _privateChatRooms = [
          AreaChatRoom(
            id: roomId,
            name: roomName,
            areaName: 'My Chat Room',
            description: description.isNotEmpty ? description : null,
            creatorId: chatService.currentUserId!,
            createdAt: DateTime.now(),
            isPublic: isPublic,
            memberCount: 1,
            memberIds: [chatService.currentUserId!],
            location: const GeoPoint(0, 0),
            radius: 0,
          ),
          ..._privateChatRooms,
        ];
      }
    });
  }

  void _addRoomToLocalStateAfterJoining(AreaChatRoom room) {
    // Check if the room is already in the list to avoid duplicates
    final isAreaRoomExists = _areaChatRooms.any((r) => r.id == room.id);
    final isPrivateRoomExists = _privateChatRooms.any((r) => r.id == room.id);

    if (isAreaRoomExists || isPrivateRoomExists) {
      return; // Skip if already in the list
    }

    setState(() {
      if (room.isPublic) {
        _areaChatRooms = [
          room,
          ..._areaChatRooms,
        ];
      } else {
        _privateChatRooms = [
          room,
          ..._privateChatRooms,
        ];
      }
    });
  }

  // Show a dialog to share room ID
  void _showShareRoomIdDialog(
      BuildContext context, String roomName, String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryPurple, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.share, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            const Text(
              'Share Chat Room',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share the Room ID for "$roomName" with your friends:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room ID:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    roomId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('COPY'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: roomId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room ID copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Share this Room ID with a friend\n'
              '2. Ask them to go to the Chat Rooms screen\n'
              '3. They should tap the "Join Room" button in the top bar\n'
              '4. They should enter this Room ID to join',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showFindRoomDialog() {
    final TextEditingController roomIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.primaryPurple,
            width: 1,
          ),
        ),
        title: const Text(
          'Find Chat Room by ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: roomIdController,
                decoration: const InputDecoration(
                  labelText: 'Room ID',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the exact room ID to find and join a specific chat room.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final roomId = roomIdController.text.trim();
              if (roomId.isNotEmpty) {
                Navigator.pop(context);
                _searchRoomById(roomId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('FIND'),
          ),
        ],
      ),
    );
  }

  // Show a dialog when a room is found with info and join button
  void _showRoomFoundDialog({
    required BuildContext context,
    required String roomName,
    required String roomId,
    required bool isPublic,
    required bool isAreaRoom,
  }) {
    bool isJoining = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPublic ? AppColors.primaryBlue : AppColors.primaryPurple,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.search,
                color:
                    isPublic ? AppColors.primaryBlue : AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Room Found: $roomName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Room Details:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              // Room information
              _buildInfoRow('Name:', roomName),
              _buildInfoRow('Type:', isAreaRoom ? 'Area Room' : 'Chat Room'),
              _buildInfoRow('Visibility:', isPublic ? 'Public' : 'Private'),
              _buildInfoRow('ID:', roomId, isMonospace: true),

              const SizedBox(height: 16),
              Text(
                isPublic
                    ? 'This is a public room. You can join to start chatting!'
                    : 'This is a private room. You need an invitation to join.',
                style: TextStyle(
                  color: isPublic ? Colors.green.shade300 : Colors.orange,
                  fontSize: 13,
                ),
              ),

              // Show loading indicator when joining
              if (isJoining)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isPublic
                                ? AppColors.primaryBlue
                                : AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Joining room...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isJoining ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('CANCEL'),
            ),
            if (isPublic)
              ElevatedButton(
                onPressed: isJoining
                    ? null
                    : () async {
                        setState(() {
                          isJoining = true;
                        });

                        try {
                          // Join the room
                          await chatService.joinChatRoom(roomId);

                          if (context.mounted) {
                            Navigator.pop(dialogContext);

                            // Create a room object for UI
                            AreaChatRoom room;

                            if (isAreaRoom) {
                              // Get the full room details
                              final fullRoom = await _locationService
                                  .getAreaChatRoomById(roomId);
                              if (fullRoom == null) return;

                              // Create a new instance with the current user added
                              room = AreaChatRoom(
                                id: fullRoom.id,
                                name: fullRoom.name,
                                areaName: fullRoom.areaName,
                                description: fullRoom.description,
                                location: fullRoom.location,
                                radius: fullRoom.radius,
                                memberIds: [
                                  ...fullRoom.memberIds,
                                  chatService.currentUserId!
                                ],
                                memberCount: fullRoom.memberCount + 1,
                                isPublic: fullRoom.isPublic,
                                creatorId: fullRoom.creatorId,
                                createdAt: fullRoom.createdAt,
                                isOfficial: fullRoom.isOfficial,
                              );
                            } else {
                              // Get the full room details
                              final fullRoom =
                                  await chatService.getChatRoomById(roomId);
                              if (fullRoom == null) return;

                              // Create AreaChatRoom from a regular ChatRoom
                              room = AreaChatRoom(
                                id: fullRoom.id,
                                name: fullRoom.name,
                                areaName: 'Joined Room',
                                memberIds: [
                                  ...fullRoom.memberIds,
                                  chatService.currentUserId!
                                ],
                                memberCount: fullRoom.memberCount + 1,
                                isPublic: fullRoom.isPublic,
                                creatorId: fullRoom.creatorId,
                                createdAt: fullRoom.createdAt,
                                location: const GeoPoint(0, 0),
                                radius: 0,
                                lastMessage: fullRoom.lastMessage,
                                lastActivity: fullRoom.lastActivity,
                              );
                            }

                            // Add room to local state
                            _addRoomToLocalStateAfterJoining(room);

                            // Show success message with option to navigate
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Successfully joined "$roomName"'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'OPEN',
                                  textColor: Colors.white,
                                  onPressed: () => _navigateToChat(
                                      context, roomName, roomId),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error joining room: ${e.toString().split(': ').last}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primaryBlue.withOpacity(0.4),
                ),
                child: const Text('JOIN ROOM'),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows in the found room dialog
  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isMonospace ? 1 : 2,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToPrivateRooms() {
    // Wait for the UI to be built, then scroll to private rooms section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _privateRoomsKey.currentContext != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            final context = _privateRoomsKey.currentContext;
            if (context != null) {
              Scrollable.ensureVisible(
                context,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              );
            }
          }
        });
      }
    });
  }
}

// Grid painter for background effect
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Horizontal lines
    final horizontalCount = 15;
    final horizontalSpacing = size.height / horizontalCount;
    for (int i = 0; i <= horizontalCount; i++) {
      final y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    final verticalCount = 15;
    final verticalSpacing = size.width / verticalCount;
    for (int i = 0; i <= verticalCount; i++) {
      final x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
