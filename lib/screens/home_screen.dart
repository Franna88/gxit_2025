import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/chat_summary_card.dart';
import '../widgets/important_message_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/contact_item.dart';
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode
                  ? AppColors.darkBackground
                  : AppColors.primaryBlue.withOpacity(0.7),
              isDarkMode
                  ? AppColors.darkBackground.withOpacity(0.9)
                  : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryPurple,
                      radius: 20,
                      child: const Text(
                        'GX',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback:
                          (bounds) =>
                              GradientPalette.gxitGradient.createShader(bounds),
                      child: Text(
                        'GXIT Chat',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
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

              // Recent Chats Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Chats',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
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

              // Recent Chats List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ChatSummaryCard(
                        name: 'JoeBanker',
                        lastMessage: 'Hey, check this out!',
                        unreadCount: 3,
                        status: ContactStatus.online,
                        onTap: () => _navigateToChat(context, 'JoeBanker'),
                      ),
                      ChatSummaryCard(
                        name: 'TradePost',
                        lastMessage: 'New trade opportunity',
                        unreadCount: 1,
                        status: ContactStatus.online,
                        onTap: () => _navigateToChat(context, 'TradePost'),
                      ),
                      ChatSummaryCard(
                        name: 'Info',
                        lastMessage: 'System update completed',
                        unreadCount: 2,
                        status: ContactStatus.online,
                        onTap: () => _navigateToChat(context, 'Info'),
                      ),
                      ChatSummaryCard(
                        name: 'Gallery',
                        lastMessage: 'Check out these photos',
                        unreadCount: 0,
                        status: ContactStatus.online,
                        onTap: () => _navigateToChat(context, 'Gallery'),
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
                          color: isDarkMode ? Colors.white70 : Colors.black87,
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
                        senderName: 'TradePost',
                        message:
                            'Your trade proposal has been accepted! Please confirm details by EOD.',
                        timestamp: DateTime.now().subtract(
                          const Duration(hours: 2),
                        ),
                        onTap: () => _navigateToChat(context, 'TradePost'),
                      ),
                      ImportantMessageCard(
                        senderName: 'JoeBanker',
                        message:
                            'URGENT: Meeting rescheduled to tomorrow at 10am. Please confirm your availability.',
                        timestamp: DateTime.now().subtract(
                          const Duration(hours: 5),
                        ),
                        onTap: () => _navigateToChat(context, 'JoeBanker'),
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
                          color: isDarkMode ? Colors.white70 : Colors.black87,
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
                          message: 'TradeGroup added 3 new members',
                          timestamp: DateTime.now().subtract(
                            const Duration(hours: 1),
                          ),
                        ),
                        ActivityCard(
                          activityType: ActivityType.fileShared,
                          message: 'Gallery shared 5 photos with you',
                          timestamp: DateTime.now().subtract(
                            const Duration(hours: 3),
                          ),
                        ),
                        ActivityCard(
                          activityType: ActivityType.groupCreated,
                          message: 'You created a new group "GXIT Team"',
                          timestamp: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey.shade600,
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
