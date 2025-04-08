import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/contact_item.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : AppColors.darkText,
            ),
            onPressed: () {},
          ),
        ],
        backgroundColor:
            isDarkMode ? AppColors.darkBackground : Colors.grey.shade100,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? AppColors.darkBackground : Colors.grey.shade100,
              isDarkMode
                  ? AppColors.darkBackground.withOpacity(0.9)
                  : Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          children: [
            // Info contact
            ContactItem(
              name: 'Info',
              hasUnreadMessage: true,
              status: ContactStatus.online,
              onTap: () => _navigateToChat(context, 'Info'),
            ),

            // Unknown contact
            ContactItem(
              name: 'unknown',
              hasUnreadMessage: true,
              status: ContactStatus.unknown,
              onTap: () => _navigateToChat(context, 'unknown'),
            ),

            // Gallery contact
            ContactItem(
              name: 'Gallery',
              status: ContactStatus.online,
              onTap: () => _navigateToChat(context, 'Gallery'),
            ),

            // JoeBanker contact
            ContactItem(
              name: 'JoeBanker',
              status: ContactStatus.online,
              onTap: () => _navigateToChat(context, 'JoeBanker'),
            ),

            // TradePost contact
            ContactItem(
              name: 'TradePost',
              status: ContactStatus.online,
              onTap: () => _navigateToChat(context, 'TradePost'),
            ),

            // Friend 1 contact
            ContactItem(
              name: 'Friend 1',
              status: ContactStatus.offline,
              onTap: () => _navigateToChat(context, 'Friend 1'),
            ),

            // Friend 2 contact
            ContactItem(
              name: 'Friend 2',
              status: ContactStatus.offline,
              onTap: () => _navigateToChat(context, 'Friend 2'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey.shade600,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
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
