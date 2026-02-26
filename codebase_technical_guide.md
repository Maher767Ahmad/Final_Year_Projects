# BGNU Digital Library - Technical Code Mapping

This guide details exactly where each core technology is implemented and how functions are distributed across the project.

---

## 💾 Local Storage (Hive)
**Purpose**: Offline storage for downloaded books.
- **Initialization**: `lib/main.dart` (Lines 13-20)
  - `Hive.initFlutter()` initializes the system.
  - `Hive.registerAdapter(DownloadedBookAdapter())` registers the data type.
  - `Hive.openBox<DownloadedBook>('downloaded_books')` opens the storage container.
- **Data Model**: `lib/models/downloaded_book_model.dart`
  - Defines the fields stored locally (title, author, file path, etc.).
- **Logic / Management**: `lib/services/download_service.dart`
  - `isBookDownloaded(id)`: Checks if a book exists in Hive.
  - `downloadBook()`: Downloads file and adds entry to `_box.add()`.
  - `deleteDownloadedBook()`: Removes file and entry using `book.delete()`.
  - `getTotalStorageUsed()`: Sums file sizes from the Hive list.

---

## 📡 API Service (Core Logic)
**Purpose**: Handles all communication with the PHP backend.
- **Base Class**: `lib/services/api_service.dart`
  - `baseUrl`: The live production URL.
  - `get()`, `post()`, `put()`, `delete()`: Generic HTTP wrappers.
  - `_handleResponse()`: Centralized error handling for non-200 status codes.
- **Implementation (Flutter)**:
  - `lib/services/auth_service.dart`: Uses `/users/register`, `/users/login`.
  - `lib/home/home_screen.dart`: Uses `/books/recent`, `/notifications/unread/`.
  - `lib/home/notifications_screen.dart`: Uses `/notifications/user/`, `/notifications/read-all/`.
  - `lib/upload/upload_book_screen.dart`: Uses `/books/upload`.
- **Backend (PHP)**:
  - `backend/db_connect.php`: Database connection and CORS headers.
  - `backend/books.php`: Logic for book search, recent books, and department filtering.

---

## 🔔 Notification System
**Purpose**: Alerts users about account approvals and new book availability.
- **Model**: `lib/models/notification_model.dart`
  - Stores `type` (approval/book_upload), `message`, and `relatedId`.
- **UI Screen**: `lib/home/notifications_screen.dart`
  - `_fetchNotifications()`: Retrieves all relevant alerts.
  - `_markAllAsRead()`: Clears the red dot badge globally.
  - `_handleNotificationTap()`: Deep-linking logic (e.g., opens a book detail from a notification).
- **Backend Generator**: 
  - `backend/approvals.php`: Creates notification when user is approved.
  - `backend/books.php`: Creates "New book uploaded" notification for all department users.

---

## 🔐 Authentication & Role Management
- **Frontend Controller**: `lib/services/auth_service.dart`
  - Managed via `ChangeNotifier` (Provider).
  - Handles login, signup, and local session persistence using `SharedPreferences`.
- **Backend Logic**: `backend/users.php`
  - Password hashing and verification.
  - Profile generation.

---

## 🔥 Firebase (Status)
- **Current Status**: **Not used** in this project.
- **Note**: This project uses a custom PHP-based authentication and notification system instead of Firebase. No Firebase SDKs are currently initialized or required.

---

## 📦 Core Dependencies (pubspec.yaml)
| Feature | Package | Used in... |
|---------|---------|------------|
| State Management | `provider` | Throughout the app for Auth and Theme |
| HTTP/API | `http`, `dio` | `ApiService`, `DownloadService` |
| Local Database | `hive` | `DownloadService`, `main.dart` |
| UI Icons/Fonts | `google_fonts` | `AppTheme` |
| PDF Viewer | `syncfusion_flutter_pdfviewer` | `pdf_viewer_screen.dart` |
| File Selection | `file_picker` | `upload_book_screen.dart` |
| Offline Path | `path_provider` | `DownloadService` |

---

## 📁 Function Mapping
| Requirement | Frontend Code | Backend Code |
|-------------|---------------|--------------|
| **Sign Up** | `auth/signup_screen.dart` | `users.php` |
| **Login** | `auth/login_screen.dart` | `users.php` |
| **Search Books**| `home/search_screen.dart` | `books.php?endpoint=/search` |
| **Upload Book** | `upload/upload_book_screen.dart` | `upload.php` (files), `books.php` (meta) |
| **Download** | `services/download_service.dart` | Static file access on server |
| **Notifications**| `home/notifications_screen.dart`| `notifications.php` |
| **Approvals** | `profile/approvals_screen.dart`| `approvals.php` |

