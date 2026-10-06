# Comprehensive Chat System Implementation Plan

This plan details the implementation of a full-featured real-time chat system using `Socket.io` and `MongoDB`, strictly adhering to Clean Architecture principles.

## 🎯 Features to Implement
1. **One-to-One Chat** & **Group Chat**
2. **Read/Unread Status & Seen By**
3. **Pagination for Previous Messages** (via Socket.io)
4. **Block / Unblock Users**
5. **Encrypted System** (End-to-End Encryption logic where the server stores encrypted strings)
6. **Temporary / Disappearing Messages** (Private chat)
7. **Chat Lock with Password**

---

## 🏗 Architecture Design (Clean Architecture)

To avoid a massive, messy `server.js` file, we will separate Socket.io logic into isolated handlers, similar to REST controllers.

### 1. New Directory Structure
- `src/sockets/` - Socket initialization and connection management.
- `src/sockets/handlers/` - Individual event handlers (like controllers for WebSockets).
- `src/services/chat.service.js` - Business logic for chats.
- `src/services/message.service.js` - Business logic for messages.

---

## 💾 Database Models (Mongoose)

### 1. `chat.model.js`
Handles both One-to-One and Group Chats.
- `isGroupChat` (Boolean)
- `chatName` (String, for groups)
- `users` (Array of ObjectIds ref 'User')
- `admin` (ObjectId ref 'User', for groups)
- `chatPassword` (String, hashed - for locked chats)
- `disappearingTimer` (Number - seconds for temporary messages, 0 if disabled)

### 2. `message.model.js`
Stores encrypted messages.
- `chat` (ObjectId ref 'Chat')
- `sender` (ObjectId ref 'User')
- `content` (String - **Encrypted AES String**)
- `readBy` (Array of ObjectIds ref 'User')
- `expiresAt` (Date - for temporary messages)

### 3. `block.model.js`
Handles user blocking to keep it decoupled from the core User model.
- `blocker` (ObjectId ref 'User')
- `blocked` (ObjectId ref 'User')

---

## 🔌 Socket.io Implementation (Event Flow)

### Connection & Authentication
- Socket middleware will verify the JWT token before allowing connection.
- **IMPORTANT**: The client MUST pass the token using the `Authorization` header in the format `Bearer <token>`. The server will strictly validate the Bearer prefix and extract the token from `socket.handshake.headers.authorization`.
- Each user will automatically join a personal room based on their `userId` for direct targeting.

### Event Definitions

#### `message.handler.js`
- **`send_message`**: Receives an encrypted message. Checks if blocked. Saves to DB. Emits `new_message` to the chat room.
- **`fetch_messages`**: Receives `chatId`, `page`, and `limit`. Fetches from DB, handles pagination, and returns via callback/acknowledgement.
- **`mark_as_read`**: Receives `messageId` and `chatId`. Updates `readBy` array. Emits `message_seen` to the sender.

#### `chat.handler.js`
- **`create_group`**: Creates a group chat. Emits `group_created` to all members.
- **`block_user` / `unblock_user`**: Adds/removes from `block.model.js`.
- **`lock_chat`**: Sets a hashed `chatPassword` on the chat.
- **`unlock_chat`**: Verifies password to allow fetching messages.
- **`set_temporary_timer`**: Enables disappearing messages for a specific chat.

---

## 🔒 Security & Privacy Features

1. **Encryption**: 
   - The Backend will **NOT** encrypt/decrypt messages. It will act as a blind relay.
   - The Flutter Frontend will encrypt the message using AES before sending via Socket, and decrypt it upon receiving. The backend only stores encrypted text.
2. **Chat Lock**: 
   - Before emitting `fetch_messages`, the server will check if the chat has a password. If it does, the client must provide the correct password hash in the payload to retrieve messages.
3. **Temporary Messages**: 
   - A MongoDB TTL (Time-To-Live) index on `expiresAt` will be used in `message.model.js`. If a chat has `disappearingTimer` active, messages will automatically get an `expiresAt` date and MongoDB will automatically delete them when the time arrives!

### 7. Media Upload Strategy (Images, Voice, Video)
To handle media messages efficiently without overloading the socket server, the frontend will use the following flow:
1. **Upload via REST API:** The Flutter app uploads the media file (image, voice note, video up to 100MB) via a `POST /api/upload` request as `multipart/form-data`. (Requires `Authorization: Bearer <token>` and field name `file`).
2. **Cloudinary Storage:** The Node.js backend streams the file to Cloudinary.
3. **Get URL:** The API responds with the secure Cloudinary URL of the uploaded file.
4. **Send via Socket:** The frontend then sends a normal `send_message` Socket event, but puts the Cloudinary URL in the `content` field.
5. **Render:** The receiver gets the `new_message` event and renders an Image/Video/Audio widget using the URL.

### 8. User Search & Username System
To allow users to find and connect with each other easily:
1. **Username Requirement:** Every user is required to choose a unique `username` during registration.
2. **Search API:** The frontend will use `GET /api/users/search?q=query` to search for users globally by their `username`, `email`, or `name`.
3. **Initiating Chat:** When a user clicks on a search result, the frontend will emit the `access_chat` Socket event with the selected user's `_id` to create a direct chat and add them to their chat list.

### 9. Chat Muting
Users can choose to mute a chat for a specific duration (e.g. 8 hours) or indefinitely.
- The `mutedBy` array in the `Chat` model stores the user ID and the exact `Date` until which the chat is muted.
- The frontend will check the `mutedUntil` date in the chat object. If the current date is before `mutedUntil`, the frontend will silence notifications/sounds for that chat.

### 10. Message Reply & Reaction System
- **Reply:** A message can reply to another message by sending a `replyTo` parameter containing the original `messageId` during the `send_message` event. The backend will store it and automatically populate the original message details when fetched.
- **Reaction:** Users can react to messages using the `react_to_message` Socket event. The backend stores an array of reactions inside the `Message` model. If a user sends the exact same emoji twice on the same message, the reaction is removed (toggle logic). The backend broadcasts `message_reacted` so UI updates in real-time.

### 11. Chat List Filters (Pin, Favourite, Archive, Read/Unread)
- **Pin, Favourite, Archive:** Handled via the `toggle_chat_action` Socket event. The `Chat` model stores `pinnedBy`, `favouritedBy`, and `archivedBy` arrays. This allows mutiple users in a group chat to have their own personal settings (e.g. I can pin a chat, but it won't be pinned for you).
- **Read/Unread:** The `Chat` model now tracks `latestMessage` which is automatically updated when a new message is sent. The frontend can check if the current user's ID exists in `latestMessage.readBy` array to determine if the chat should be shown as unread.
- **Sorting:** `fetch_chats` sorts all chats by `updatedAt` in descending order, and populates the `latestMessage` so the frontend has everything needed to render the chat list perfectly.

### 12. Delete Chat, Clear History & Pinned Messages
- **Delete Chat / Clear History:** Deleting a chat hides it from the user's chat list by adding them to a `deletedBy` array, and records the exact time in `clearedHistory`. The `fetch_messages` endpoint will only return messages created *after* the `clearedHistory` timestamp. If a new message is received in a deleted chat, it is removed from `deletedBy` and reappears in the list automatically. (Implemented via `delete_chat` and `clear_history` socket events).
- **Pinned Messages:** Group or one-to-one chats can have pinned messages. Handled via `toggle_pin_message` socket event, saving an array of message IDs in the `Chat` model.

### 13. Important Note on Message Search
- Because we are strictly following an **End-to-End Encryption** model, the backend database ONLY stores **encrypted AES strings** for all messages. 
- Therefore, searching for message content on the server-side (like regex or `$text` search) is technically **impossible**.
- **Solution:** Message searching MUST be done entirely on the **Frontend (Flutter)**. The frontend will fetch the messages, decrypt them, and run a local search against the decrypted texts. This ensures 100% privacy and security.

### 14. Single Message Deletion
- **Delete for Me:** The `Message` model has a `deletedFor` array. If a user deletes a message for themselves, their ID is added here. The `fetch_messages` endpoint excludes these messages for that user.
- **Delete for Everyone:** Only the sender can do this. It sets `isDeletedForEveryone: true` and replaces the `content` string with "This message was deleted" on the server. The socket broadcasts `message_deleted_for_everyone` so all clients in the room update their UI immediately.

### 15. Discover Nearby Friends & Advanced Filtering
- **User Profile Fields:** The `User` model now contains `gender`, `age`, `passion` (array of hobbies), and a GeoJSON `location` (latitude/longitude) with a `2dsphere` index. These can be passed during Signup (`POST /api/auth/register`).
- **Discover API:** A new REST endpoint `GET /api/users/discover` lets the frontend fetch and filter users based on:
  - Location (passing `lat`, `lng`, and `maxDistance` in km).
  - Demographics (passing `minAge`, `maxAge`, `gender`).
  - Interests (passing `passion` as a comma-separated string, e.g., `passion=coding,music`).
- This allows building a "Find Friends Nearby" screen similar to Tinder or WeChat's Shake/Nearby features.

### 16. Profile Update & Profile Image
- **Profile Image Field:** Added `profileImage` (String) to the `User` model to store the Cloudinary URL.
- **Update Profile API:** A new endpoint `PUT /api/users/profile` allows users to update their details after signup.
- **Payload Example:**
```json
{
  "name": "Updated Name",
  "gender": "Female",
  "age": 26,
  "passion": ["reading", "dancing"],
  "profileImage": "https://res.cloudinary.com/.../image.jpg",
  "location": {
    "lat": 23.8103,
    "lng": 90.4125
  }
}
```
- **Flow for Profile Image:** The Flutter app should first upload the image file via the existing `POST /api/upload` API. Once it gets the Cloudinary URL in response, it should pass that URL to `PUT /api/users/profile` in the `profileImage` field.
