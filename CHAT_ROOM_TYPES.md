# Chat Room Types and Categorization

This document explains how different types of chat rooms are created and categorized in the app.

## Chat Room Types

### 1. Public Chat Rooms
- **Settings**: `isPublic = true`, `isDirectMessage = false`
- **Creation**: Created through the "Create Room" dialog with "Public" selected
- **Display**: Appears in the "Area Rooms" or "Public Chat Rooms" section
- **Access**: Anyone can join these rooms
- **Use Case**: Community discussions, public topics

### 2. Private Chat Rooms
- **Settings**: `isPublic = false`, `isDirectMessage = false`
- **Creation**: Created through the "Create Room" dialog with "Private" selected
- **Display**: Appears in the "Private Chat Rooms" section
- **Access**: Only invited members can join
- **Use Case**: Private group discussions, exclusive communities
- **Important**: Private chat rooms remain private chat rooms regardless of how many users are invited at once

### 3. Direct Messages
- **Settings**: `isPublic = false`, `isDirectMessage = true`
- **Creation**: Created through the Contacts screen when messaging a specific user
- **Display**: Appears only in the "Active Chats" section (not in chat room sections)
- **Access**: Only the two participants
- **Use Case**: 1-on-1 conversations between users

## Current Implementation Status

✅ **FIXED**: Private chat rooms are now correctly preserved as private chat rooms and not incorrectly converted to direct messages when inviting users.

✅ **FIXED**: Private chat rooms (both created by the user and those they were invited to join) are now properly displayed in the Private Chat Room category on the Home page.

✅ **WORKING CORRECTLY**: When a user creates a chat room and sets it to "Private", it is correctly saved as a Private Chat Room (not a Direct Message) and appears in the "Private Chat Rooms" section.

✅ **UPDATED**: Private chat rooms are now excluded from the "Active Chats" section and appear only in the "Private Chat Rooms" section, ensuring clear separation between private group chats and direct messages.

## Key Implementation Details

- The `isDirectMessage` flag is set only during room creation and should never be changed afterward
- Private chat rooms can invite users one at a time without becoming direct messages
- The invitation system preserves the original room type regardless of invitation count
- Direct messages are only created through the Contacts screen for 1-on-1 conversations
- Home page navigation now properly uses room IDs to navigate to existing chat rooms
- Both created and joined private chat rooms appear in the Private Chat Rooms section

## UI Sections

1. **Area Rooms / Public Chat Rooms**: Shows public chat rooms (`isPublic = true`, `isDirectMessage = false`)
2. **Private Chat Rooms**: Shows private chat rooms without recent activity (`isPublic = false`, `isDirectMessage = false`, no activity in last 7 days)
3. **Active Chats**: Shows:
   - All direct messages (`isDirectMessage = true`)
   - Any chat rooms (public or private) with recent activity in the last 7 days
   - This ensures recently active private rooms appear here instead of cluttering the Private Rooms section

## Code Locations

- Chat room creation: `lib/services/chat_service.dart` - `createChatRoom()` method
- Private room display: `lib/widgets/private_rooms_section.dart`
- Invitation system: `lib/services/chat_service.dart` - `inviteUsersToChatRoom()` and `acceptChatInvitation()` methods
- Home page navigation: `lib/screens/home_screen.dart` - `_navigateToChatRoom()` method
- Private room fetching: `lib/services/location_service.dart` - `getPrivateChatRooms()` method

## Summary

The system correctly distinguishes between:
- **Private Chat Rooms**: Group chats that are private but not direct messages
- **Direct Messages**: 1-on-1 conversations between two users

Private chat rooms created by users or that users were invited to join now properly appear in the Private Chat Rooms section on the Home page and can be navigated to correctly. 