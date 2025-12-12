# IoT Event Feed iOS App

A modern iOS application built with SwiftUI for monitoring IoT device events with offline support, real-time updates, and file management capabilities.

## Features

### 🔐 Authentication & User Management

- **Secure Login** - JWT-based authentication with secure token storage in Keychain
- **User Profile** - View user profile and manage downloadable content
- **Session Management** - Automatic token refresh and secure logout functionality
- **Persistent Sessions** - App remembers logged-in state across launches

### 📱 Event Feed

#### Core Features
- **Event List** - Chronological display of IoT events sorted by timestamp (newest first)
- **Severity Indicators** - Color-coded severity levels (info, warning, critical) for quick visual identification
- **Event Cards** - Clean, readable event cards showing key information at a glance

#### Pagination & Loading
- **Cursor-based Pagination** - Efficient infinite scrolling using cursor-based pagination
- **Infinite Scroll** - Automatically loads more events as you scroll down
- **Pull-to-Refresh** - Swipe down to manually refresh and fetch latest events
- **Loading States** - Clear visual feedback during initial load and pagination
- **Empty States** - User-friendly messages when no events are available

#### Real-time Updates
- **Background Polling** - Automatically checks for new events every 30 seconds
- **New Events Banner** - Visual notification banner showing:
  - Total count of new events
  - Count of critical events (highlighted)
  - One-tap refresh button
- **Smart Polling** - Only polls when online and events are loaded
- **Polling Control** - Automatically starts/stops based on view lifecycle

#### Network & Offline Support
- **Network Monitoring** - Real-time network connectivity detection using Network framework
- **Offline Indicators** - Visual banners when device is offline
- **Offline Mode** - Full app functionality using cached data when offline
- **Graceful Degradation** - Seamless transition between online and offline modes

### 📄 Event Details

- **Comprehensive View** - Full event information including:
  - Device information (name, ID)
  - Event details (type, severity, message)
  - Location information
  - Timestamps (full date/time and relative time)
  - Technical details (event ID)
- **Severity Display** - Prominent severity indicator with color coding
- **Refresh Capability** - Manual refresh button to get latest event data
- **File Attachments** - Download and view log files associated with events

### 📥 File Management

#### Download Features
- **File Downloads** - Download log files from events with progress tracking
- **Download Progress** - Real-time progress indicators showing download percentage
- **Download Cancellation** - Cancel ongoing downloads
- **Network Awareness** - Download button disabled when offline
- **Duplicate Prevention** - Prevents re-downloading already downloaded files

#### File Viewing & Management
- **File Viewer** - Built-in text viewer for downloaded files with monospaced font
- **File Sharing** - Share downloaded files via iOS native share sheet
- **Download History** - View all downloaded files in profile section
- **File Metadata** - Display file size, download date, and associated event ID
- **File Deletion** - Remove downloaded files to free up storage space
- **Offline Access** - View downloaded files without internet connection

#### Storage
- **Local Storage** - Files stored in app's Documents directory
- **SwiftData Integration** - Download metadata persisted using SwiftData
- **Automatic Cleanup** - Removes database entries for files that no longer exist on disk

### 💾 Offline Support

- **Local Caching** - Events cached locally using SwiftData for offline access
- **Cache Management** - Automatic cache updates when online
- **Offline Browsing** - Browse cached events without internet connection
- **Cache Pagination** - Pagination works with cached data when offline
- **Smart Caching** - Prevents duplicate entries in cache

## Architecture

### Design Patterns
- **MVVM** - Model-View-ViewModel architecture
- **Observable Pattern** - Using Swift's `@Observable` macro for reactive updates
- **Dependency Injection** - Services injected via SwiftUI `Environment`

### Key Components

#### Models
- `Event` - Event data model with SwiftData persistence
- `User` - User profile model
- `FileDownload` - File download metadata model

#### Views
- `EventFeedView` - Main event feed with pagination and polling
- `EventDetailView` - Detailed event view
- `ProfileView` - User profile and download history
- `FileDownloadView` - File download UI component
- `FileContentView` - File content viewer

#### ViewModels
- `EventFeedViewModel` - Manages event feed state, pagination, and polling
- `LoginViewModel` - Handles authentication logic

#### Services
- `APIService` - API client for backend communication
- `AppSession` - Session management and authentication state
- `FileDownloadService` - File download management and storage
- `NetworkMonitor` - Network connectivity monitoring
- `NetworkClient` - HTTP client wrapper
- `KeychainService` - Secure token storage
- `Logger` - Centralized logging service

### Data Persistence

- **SwiftData** - Used for local data persistence
  - Events are cached for offline access
  - File download metadata is stored
  - User session information is persisted

### Networking

- **URLSession** - Native iOS networking with async/await
- **JWT Authentication** - Bearer token authentication
- **Error Handling** - Comprehensive error handling with user-friendly messages
- **Request Retry** - Automatic retry logic for failed requests

## Requirements

- **iOS Version**: iOS 17.0 or later
- **Xcode**: Xcode 15.0 or later
- **Swift**: Swift 5.9 or later
- **Backend**: Backend server must be running (see [Backend README](../../backend/README.md))

## Setup & Installation

1. **Open Project**
   ```bash
   open ios/IoTEventFeedApp/IoTEventFeedApp.xcodeproj
   ```

2. **Configure Backend URL**
   - The app uses `NetworkClient` to connect to the backend
   - Default backend URL is configured in `NetworkClient`
   - Update if your backend runs on a different host/port

3. **Build & Run**
   - Select your target device or simulator (iOS 17+)
   - Select provisioning profile if target is a device
   - Build and run (⌘R)

## Usage

### First Launch
1. Enter credentials (see default users in [Backend README](../../backend/README.md))
2. Tap "Login"
3. App will load events and start polling for updates

### Using the Event Feed
- **Scroll down** to load more events automatically
- **Pull down** to refresh and fetch latest events
- **Tap an event** to view details
- **Tap the menu** (⋯) in the top right to logout

### Downloading Files
1. Open an event that has a file attachment
2. Tap "Download Log File" button
3. Monitor progress in real-time
4. Once downloaded, tap the file card to view content
5. Use share button to share the file
6. Use delete button to remove the file

### Viewing Downloaded Files
1. Navigate to Profile tab
2. Scroll to "Downloaded Files" section
3. Tap any file to view its content
4. Use share or delete buttons as needed

### Offline Usage
- App automatically uses cached data when offline
- Downloaded files remain accessible offline
- Network status is indicated by banners
- Polling automatically stops when offline

## Configuration

### Backend URL
Update the backend URL in `NetworkClient.swift` if needed:
```swift
let baseURL = "http://localhost:8080"
```

### Polling Interval
Adjust polling interval in `EventFeedViewModel.swift`:
```swift
private static let pollingInterval: UInt64 = 30_000_000_000 // 30 seconds
```

### File Download Service
Enable throttling to better see the progress of downloading files in `FileDownloadService.swift`:
```swift
    #if DEBUG
    // Enable/Disable this to use throttling to check the file download progress
    let USE_THROTTLING = true
    #endif
```
This code is for demo and testing purposes only and must be removed in a deployment.
The same can be achieved outside the app code using Network Link Conditioner, Proxy, etc.

## Troubleshooting

### App won't connect to backend
- Ensure backend server is running
- Check backend URL configuration
- Verify network connectivity

### Files not downloading
- Check network connection
- Verify file exists on backend
- Check available storage space

### Events not updating
- Check network connection
- Verify polling is enabled (should start automatically)
- Try pull-to-refresh manually

## Known limitations
- Tested with Xcode 16.4 and iOS 18.6
- No tests coverage, though the components are designed with testability in mind
- The sample log files need to be generated beforehand
- The events storage is in memory. The events are generated when the server is run so events will have different IDs and timestamps between runs
- The details page does fetch the event details using the API, however, the full data of the event is returned by both the list/feed and details APIs. The call is not needed to present the additional events fields but is done to show case how it can be implemented
- When switching from offline to online, if there are more new events than page count, the feed view will display only the new events, otherwise it will append on top. This is done in order to prevent gaps between the new data and cached data when there are many new events
- The cached events count is not limited, consider implementing a sliding expiration
- The file storage size is not limited, consider setting a max total file size to store
- The cached data and files are not stored per user
