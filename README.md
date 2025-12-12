# IoT Event Feed

A lightweight platform for monitoring and displaying IoT device events with a modern iOS app and RESTful backend API.

## Overview

This project provides a solution for IoT event monitoring:
- A **lightweight backend** service providing event APIs, authentication, and file downloads
- An **iOS application** with offline support, real-time updates, and file management

## Features

### iOS App

#### Authentication & User Management
- **Secure Login** - JWT-based authentication with secure token storage
- **User Profile** - View user details
- **Session Management** - Automatic token refresh and secure logout

#### Event Feed
- **Event List** - Chronological display of IoT events with severity indicators
- **Cursor-based Pagination** - Efficient infinite scrolling for large datasets
- **Pull-to-Refresh** - Manual refresh to fetch latest events
- **Background Polling** - Automatic checking for new events every 30 seconds
- **New Events Banner** - Visual notification showing count of new events (including critical count)
- **Loading States** - Clear feedback during data fetching
- **Empty States** - User-friendly messages when no events are available
- **Error Handling** - Graceful error messages with retry options

#### Event Details
- **Comprehensive View** - Full event information including device details, location, timestamps
- **Severity Indicators** - Color-coded severity levels (info, warning, critical)
- **Refresh Capability** - Manual refresh to get latest event data
- **File Attachments** - Download and view log files associated with events

#### File Management
- **File Downloads** - Download log files from events with progress tracking
- **Download Progress** - Real-time progress indicators during downloads
- **File Viewer** - Built-in text viewer for downloaded files
- **File Sharing** - Share downloaded files via iOS share sheet
- **Download History** - View all downloaded files in profile section
- **File Deletion** - Remove downloaded files to free up storage
- **Offline Access** - View downloaded files without internet connection

#### Offline Support
- **Local Caching** - Events cached locally using SwiftData for offline access
- **Network Monitoring** - Real-time network connectivity detection
- **Offline Indicators** - Visual banners when offline
- **Graceful Degradation** - App works offline with cached data

### Backend

#### API Features
- **RESTful API** - Clean REST endpoints following standard conventions
- **JWT Authentication** - Stateless authentication with secure token generation
- **Password Security** - bcrypt password hashing for secure credential storage
- **Event Management** - Full CRUD operations for IoT events
- **Cursor-based Pagination** - Reliable pagination using timestamp + event ID cursors
- **New Events Polling** - Endpoint to check for new events without fetching full data
- **File Downloads** - Secure file serving with proper headers and streaming

#### Architecture
- **Thread-Safe Storage** - In-memory mock store with `sync.RWMutex` for concurrent access
- **Layered Architecture** - Separation of concerns (handlers, models, middleware, routes)
- **Error Handling** - Consistent error response format across all endpoints
- **Request Logging** - Comprehensive logging for debugging and monitoring

For detailed backend documentation, see [Backend README](backend/README.md).  
For iOS app details, see [iOS README](ios/IoTEventFeedApp/README.md).

## 🛠 Technologies

### iOS
- **Language**: Swift
- **Minimum iOS Version**: iOS 17+
- **Frameworks**: SwiftUI, SwiftData, Combine, Network
- **Architecture**: MVVM with Observable pattern
- **Storage**: SwiftData for local persistence
- **Networking**: URLSession with async/await

### Backend
- **Language**: Go 1.24+
- **Framework**: Gin (HTTP web framework)
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcrypt
- **Storage**: In-memory mock store (thread-safe)

## 🚀 Running the Project

### Backend

See [Backend README](backend/README.md) for detailed installation and running instructions.

Quick start:
```bash
cd backend
go run main.go
```

The server will start on port `8080` by default.

### iOS App

1. Open `ios/IoTEventFeedApp/IoTEventFeedApp.xcodeproj` in Xcode
2. Select your target device or simulator (iOS 17+)
3. Build and run (⌘R)

**Note**: Make sure the backend server is running before using the app.

## 📁 Project Structure

```
IoTEventFeed/
├── backend/              # Go backend service
│   ├── handlers/        # Request handlers
│   ├── models/          # Data models
│   ├── middleware/      # HTTP middleware
│   ├── routes/          # API routes
│   ├── store/           # Data storage layer
│   └── auth/            # Authentication utilities
├── ios/                  # iOS application
│   └── IoTEventFeedApp/
│       ├── Models/      # Data models
│       ├── Views/       # SwiftUI views
│       ├── ViewModels/  # View models
│       └── Services/    # Business logic services
└── README.md            # This file
```

## 🔐 Default Credentials

The backend comes with three test users:

| Username | Password    | Role         |
|----------|-------------|--------------|
| admin    | admin123    | administrator|
| user1    | password123 | user         |
| demo     | demo123     | user         |

## 📝 API Documentation

For complete API documentation, see [Backend README](backend/README.md#api-endpoints).

Key endpoints:
- `POST /api/login` - Authenticate and get JWT token
- `GET /api/events` - List events with pagination
- `GET /api/events/:id` - Get event details
- `GET /api/events/new/count` - Check for new events count
- `GET /api/files/:filename` - Download log files
- `GET /api/user/:id` - Get user profile

## 🤝 Contributing

This is a demonstration project.