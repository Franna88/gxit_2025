import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/chat_summary_card.dart';
import '../widgets/important_message_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/contact_item.dart';
import '../widgets/chat_room_card.dart';
import 'contacts_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 2) {
      // Contacts tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ContactsScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? GradientPalette.darkGradient
                  : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.lightBackground, Colors.white],
                  ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor:
                    isDarkMode ? Colors.transparent : AppColors.lightBackground,
                elevation: 0,
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryPurple,
                      radius: 20,
                      child: const Text(
                        'SB',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Social Buzz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),

              // Welcome section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Text(
                    'Welcome back, User!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.darkText,
                    ),
                  ),
                ),
              ),

              // Chat Rooms Section (previously Recent Chats)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chat Rooms',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat Rooms List (updated to show topic-oriented chats)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ChatRoomCard(
                        name: 'Photography Lovers',
                        lastMessage: 'Emma: Check out my new portrait shots!',
                        lastActivity: DateTime.now().subtract(
                          const Duration(minutes: 5),
                        ),
                        memberCount: 126,
                        hasUnreadMessages: true,
                        unreadCount: 3,
                        onTap:
                            () =>
                                _navigateToChat(context, 'Photography Lovers'),
                      ),
                      ChatRoomCard(
                        name: 'Music Festival',
                        lastMessage:
                            "Alex: Who's going to Coachella this year?",
                        lastActivity: DateTime.now().subtract(
                          const Duration(hours: 1),
                        ),
                        memberCount: 84,
                        hasUnreadMessages: true,
                        unreadCount: 5,
                        onTap: () => _navigateToChat(context, 'Music Festival'),
                      ),
                      ChatRoomCard(
                        name: 'Travel Adventures',
                        lastMessage:
                            'Rachel: Just booked my flight to Thailand!',
                        lastActivity: DateTime.now().subtract(
                          const Duration(hours: 6),
                        ),
                        memberCount: 53,
                        hasUnreadMessages: false,
                        onTap:
                            () => _navigateToChat(context, 'Travel Adventures'),
                      ),
                      ChatRoomCard(
                        name: 'Gaming Squad',
                        lastMessage: 'Michael: Anyone up for Fortnite tonight?',
                        lastActivity: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        memberCount: 98,
                        hasUnreadMessages: false,
                        onTap: () => _navigateToChat(context, 'Gaming Squad'),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Contacts Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Chats',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Contacts List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ChatSummaryCard(
                        name: 'Alex',
                        lastMessage: 'Hey, are you free tonight?',
                        unreadCount: 3,
                        status: ContactStatus.online,
                        onTap: () => _navigateToChat(context, 'Alex'),
                      ),
                      ChatSummaryCard(
                        name: 'Emma',
                        lastMessage: 'Check out this photo!',
                        unreadCount: 1,
                        status: ContactStatus.online,
                        onTap: () => _navigateToChat(context, 'Emma'),
                      ),
                      ChatSummaryCard(
                        name: 'Michael',
                        lastMessage: 'Game night tomorrow?',
                        unreadCount: 2,
                        status: ContactStatus.away,
                        onTap: () => _navigateToChat(context, 'Michael'),
                      ),
                      ChatSummaryCard(
                        name: 'Jessica',
                        lastMessage: 'Thanks for the birthday wishes!',
                        unreadCount: 0,
                        status: ContactStatus.offline,
                        onTap: () => _navigateToChat(context, 'Jessica'),
                      ),
                    ],
                  ),
                ),
              ),

              // Important Messages Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Important Messages',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Important Messages List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ImportantMessageCard(
                        senderName: 'SocialBuzz',
                        message:
                            'Party at Emma\'s place this Friday! RSVP by tomorrow evening.',
                        timestamp: DateTime.now().subtract(
                          const Duration(hours: 2),
                        ),
                        onTap: () => _navigateToChat(context, 'SocialBuzz'),
                      ),
                      ImportantMessageCard(
                        senderName: 'TravelGroup',
                        message:
                            'REMINDER: Group trip planning meeting tomorrow at 7pm via video call. Please bring destination ideas!',
                        timestamp: DateTime.now().subtract(
                          const Duration(hours: 5),
                        ),
                        onTap: () => _navigateToChat(context, 'TravelGroup'),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Activity Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? AppColors.subtleText
                                  : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View More',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Activity List
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ActivityCard(
                          activityType: ActivityType.newMember,
                          message:
                              'Carlos and 3 others joined Photography Lovers',
                          timestamp: DateTime.now().subtract(
                            const Duration(hours: 1),
                          ),
                        ),
                        ActivityCard(
                          activityType: ActivityType.fileShared,
                          message:
                              'Emma shared vacation photos in Travel Adventures',
                          timestamp: DateTime.now().subtract(
                            const Duration(hours: 3),
                          ),
                        ),
                        ActivityCard(
                          activityType: ActivityType.groupCreated,
                          message: 'Michael created a new group "Movie Night"',
                          timestamp: DateTime.now().subtract(
                            const Duration(hours: 5),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor:
              isDarkMode ? AppColors.darkSecondaryBackground : Colors.white,
        ),
        child: BottomNavigationBar(
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor:
              isDarkMode ? AppColors.subtleText : Colors.grey.shade600,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String contactName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contactName: contactName),
      ),
    );
  }
}
