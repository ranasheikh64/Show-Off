# Flutter Chat App Implementation Plan

## 📌 Architecture & Guidelines
- **Architecture**: Clean Architecture (Model, Controller, Service/Provider, View/Screen).
- **State Management & DI**: GetX (`get`).
- **Routing**: `go_router` (GetX routing will not be used).
- **Networking**: `dio`.
- **Local Storage**: `hive`.
- **Responsive UI**: `flutter_screenutil`.
- **Sockets**: `socket_io_client`.
- **Design Theme**: Sky Blue color palette with modern, premium UI.
- **Strict Rule**: Maximum **120 lines of code** per file. Large UI files must be broken down into smaller components stored in a `widgets` folder within that feature.

## 📁 Core Project Structure
```text
lib/
 ├── core/
 │    ├── constants/
 │    │    ├── api_url.dart         # All API base URLs and endpoints
 │    │    ├── custom_assets.dart   # Image & Icon paths
 │    │    └── app_theme.dart       # Sky blue colors, text styles, themes
 │    ├── network/
 │    │    └── dio_client.dart      # Dio setup, interceptors (for Bearer token)
 │    ├── storage/
 │    │    └── hive_service.dart    # Hive box initializations & queries
 │    └── widgets/                  # Global Reusable Widgets
 │         ├── custom_button.dart
 │         └── custom_text_field.dart
 ├── features/
 │    ├── auth/
 │    │    ├── models/
 │    │    ├── services/
 │    │    ├── controllers/
 │    │    ├── screens/
 │    │    └── widgets/
 │    └── chat/
 │         ├── models/
 │         ├── services/           # Socket & API services
 │         ├── controllers/
 │         ├── screens/
 │         └── widgets/
 ├── routes/
 │    └── app_router.dart          # GoRouter configuration
 └── main.dart                     # Entry point, ScreenUtil initialization
```

---

## 📝 Detailed Task List

### Phase 1: Project Setup & Core Configuration
- [ ] Initialize new Flutter project.
- [ ] Add dependencies (`get`, `go_router`, `dio`, `hive`, `flutter_screenutil`, `socket_io_client`, `encrypt` for E2E encryption).
- [ ] Setup `Hive` initialization and `ScreenUtilInit` in `main.dart`.
- [ ] Create `core/constants/app_theme.dart` (Sky Blue premium palette).
- [ ] Create `core/constants/api_url.dart`.
- [ ] Create `core/network/dio_client.dart` with token interceptor.
- [ ] Set up `routes/app_router.dart`.

### Phase 2: Common UI Components
- [ ] Create `custom_button.dart` (loading states, premium look).
- [ ] Create `custom_text_field.dart` (sleek design, validation).
- [ ] Create `custom_assets.dart`.

### Phase 3: Complete Authentication Flow
- [ ] **Models**: Create `UserModel`.
- [ ] **Service & Controller**: `AuthService` and `AuthController` with token storage.
- [ ] **UI**: `LoginScreen` & `RegisterScreen`.
- [ ] **UI**: `ForgetPasswordScreen` (Request OTP).
- [ ] **UI**: `VerifyOtpScreen` (Enter OTP).
- [ ] **UI**: `ResetPasswordScreen` (Set new password).
- [ ] **UI**: `ProfileUpdateScreen` (Update details, Profile image upload via Cloudinary).
- [ ] *Constraint Check*: Ensure no file exceeds 120 lines.

### Phase 4: Chat Feature Foundation & Socket Setup
- [ ] **Models**: `ChatModel`, `MessageModel`, `ReactionModel`.
- [ ] **Service**: `SocketService` connecting with `Authorization: Bearer <token>`.
- [ ] **Service**: `ChatApiService` (REST API for fetching chats, discovering users, media upload).
- [ ] **E2E Encryption**: Implement AES Encryption/Decryption utility in Flutter (Frontend).

### Phase 5: Chat UI & Core Messaging (E2E Encrypted)
- [ ] **UI**: `ChatListScreen` (Sort by `updatedAt`, Read/Unread indicators).
- [ ] **UI**: `ChatDetailScreen` (One-to-One and Group Chat UI).
- [ ] **UI Widgets**: `MessageBubbleWidget` supporting text and Media (Images, Video, Voice).
- [ ] **Feature**: Send text message (Encrypt before sending).
- [ ] **Feature**: Receive message (Decrypt on receive).
- [ ] **Feature**: Pagination (Fetch previous messages on scroll up).
- [ ] **Feature**: Read receipts (Mark as read, Seen By indicators).

### Phase 6: Advanced Chat Features
- [ ] **Feature**: Create Group Chat (Select users).
- [ ] **Feature**: User Search (Global search via Username) to initiate chats.
- [ ] **Feature**: Discover Nearby Friends (Filter by Location, Age, Gender, Passion).
- [ ] **Feature**: Media Upload (Upload to REST API -> get Cloudinary URL -> send via Socket).
- [ ] **Feature**: Message Reply & Emoji Reactions.
- [ ] **Feature**: Delete Message (For Me & For Everyone).
- [ ] **Feature**: Frontend Local Message Search (Decrypt all and search text).

### Phase 7: Privacy, Security & Filters
- [ ] **Feature**: Block / Unblock Users.
- [ ] **Feature**: Chat Lock (Enter password to view messages).
- [ ] **Feature**: Temporary / Disappearing Messages (Set timer).
- [ ] **Feature**: Chat Actions (Pin, Favourite, Archive, Mute Chat).
- [ ] **Feature**: Delete Chat & Clear History.

---
*Awaiting review and confirmation to begin Phase 1.*
