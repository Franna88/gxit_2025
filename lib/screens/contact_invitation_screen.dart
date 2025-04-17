import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/contacts_service.dart';
import '../constants.dart';

class ContactInvitationScreen extends StatefulWidget {
  const ContactInvitationScreen({super.key});

  @override
  State<ContactInvitationScreen> createState() =>
      _ContactInvitationScreenState();
}

class _ContactInvitationScreenState extends State<ContactInvitationScreen> {
  final ContactsService _contactsService = ContactsService();
  List<Contact>? _contacts;
  bool _isLoading = true;
  String _searchQuery = '';
  List<Contact> _selectedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _contactsService.getDeviceContacts();

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load contacts')),
        );
      }
    }
  }

  List<Contact> _getFilteredContacts() {
    if (_contacts == null) return [];
    if (_searchQuery.isEmpty) return _contacts!;

    return _contacts!.where((contact) {
      final name = contact.displayName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  Future<void> _inviteSelectedContacts() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    final message =
        'Hey! Join me on GXIT, a great new app for chatting. Download it now!';

    // For now, we'll just share the invitation message
    await _contactsService.shareAppInvitation(message);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredContacts = _getFilteredContacts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Contacts'),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _contacts == null || _contacts!.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.contact_phone,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No contacts found',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey
                                        : Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadContacts,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          final isSelected = _selectedContacts.contains(
                            contact,
                          );

                          return ListTile(
                            leading:
                                contact.photo != null
                                    ? CircleAvatar(
                                      backgroundImage: MemoryImage(
                                        contact.photo!,
                                      ),
                                    )
                                    : CircleAvatar(
                                      backgroundColor: AppColors.primaryBlue,
                                      child: Text(
                                        contact.displayName.isNotEmpty
                                            ? contact.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            title: Text(contact.displayName),
                            subtitle:
                                contact.phones.isNotEmpty
                                    ? Text(contact.phones.first.number)
                                    : const Text('No phone number'),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged:
                                  (_) => _toggleContactSelection(contact),
                              activeColor: AppColors.primaryBlue,
                            ),
                            onTap: () => _toggleContactSelection(contact),
                          );
                        },
                      ),
            ),
            if (_selectedContacts.isNotEmpty)
              Container(
                color: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedContacts.length} selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _inviteSelectedContacts,
                      icon: const Icon(Icons.send),
                      label: const Text('Invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
