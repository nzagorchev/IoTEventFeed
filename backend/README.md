# IoT Event Feed Backend

A lightweight backend service built with Go and Gin framework that provides APIs for authentication, event management, and file downloads for an IoT event monitoring system.

## Architecture

### Technology Stack
- **Language**: Go 1.24+
- **Framework**: Gin (HTTP web framework)
- **Authentication**: JWT (JSON Web Tokens) with bcrypt password hashing
- **Storage**: In-memory mock store with thread-safe operations
- **IDs**: UUIDs (GUIDs) for users and events

### Architecture Decisions

1. **RESTful API Design**: Clean REST endpoints following standard conventions
2. **JWT Authentication**: Stateless authentication using JWT tokens for scalability
3. **Cursor-Based Pagination**: Reliable pagination using timestamp + event ID cursors
4. **In-Memory Storage**: Mock store for simplicity and development
5. **Layered Architecture**: Separation of concerns with handlers, models, middleware, and routes
6. **Error Handling**: Consistent error response format across all endpoints
7. **Thread Safety**: `sync.RWMutex` for concurrent access to shared data structures

### Project Structure

```
backend/
├── main.go                    # Application entry point
├── models/                    # Data models
├── store/                     # Data storage layer
│   └── mock_store.go         # In-memory mock store with thread-safe operations
├── handlers/                  # Request handlers
│   ├── auth.go               # Authentication handler
│   ├── user.go               # User profile handler
│   ├── event.go              # Event listing and details handler
│   └── file.go               # File download handler
├── middleware/                # HTTP middleware
│   ├── auth.go               # JWT authentication middleware
├── auth/                      # Authentication utilities
├── routes/                    # Route configuration
│   └── routes.go             # API route setup
└── scripts/                   # Utility scripts
```

## Prerequisites

- Go 1.24 or higher

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
go mod download
```

## Running the Server

### Basic Usage

```bash
go run main.go
```

The server will start on port `8080` by default.

### Custom Port

```bash
go run main.go -port 3000
```

### Build and Run

```bash
# Build
go build -o backend main.go

# Run
./backend
```

## API Endpoints

### Authentication

#### Login
```http
POST /api/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "username": "admin",
    "email": "admin@ioteventfeed.com",
    "name": "Admin User",
    "role": "administrator"
  }
}
```

#### Default Users

The backend comes with three hardcoded users for testing:

| Username | Password | Role         |
|----------|----------|--------------|
| admin    | admin123 | administrator|
| user1    | password123 | user      |
| demo     | demo123  | user         |

### Events

#### Get Events (Latest)
```http
GET /api/events?limit=50
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional, default: 20, max: 100): Maximum number of events to return

**Response:**
```json
{
  "events": [...],
  "has_next": true,
  "next_cursor": {
    "timestamp": 1705312200000,
    "event_id": "uuid-of-last-event"
  }
}
```

#### Get Older Events (Pagination)
```http
GET /api/events?after_ts=1705312200000&after_id=event-uuid
Authorization: Bearer <token>
```

**Query Parameters:**
- `after_ts` (required): Unix timestamp in milliseconds - get events older than this
- `after_id` (optional): Event ID for precise filtering - prevents duplicates
- **Fixed page size:** Always returns 20 events

#### Refresh (Get Newer Events)
```http
GET /api/events?before_ts=1705312200000&before_id=event-uuid
Authorization: Bearer <token>
```

**Query Parameters:**
- `before_ts` (required): Unix timestamp in milliseconds - get events newer than this
- `before_id` (optional): Event ID for precise filtering - prevents duplicates
- **Fixed page size:** Always returns 20 events

#### Get Event by ID
```http
GET /api/events/:id
Authorization: Bearer <token>
```

### User Profile

#### Get User Profile
```http
GET /api/user/:id
Authorization: Bearer <token>
```

### File Downloads

#### Download Log File
```http
GET /api/files/:filename
Authorization: Bearer <token>
```

Files are streamed with appropriate headers for download.

## Pagination

The API uses **cursor-based pagination** for reliable event fetching:

### Features
- **No skipped events**: Cursor prevents gaps when page size changes
- **Fixed page size**: 20 events when using cursors (`after_ts` or `before_ts`)
- **Flexible initial load**: Use `limit` parameter for latest events (up to 100)
- **Refresh support**: Use `before_ts` to fetch newer events
- **Backward pagination**: Use `after_ts` to fetch older events

### Example Flow

```bash
# 1. Initial load - get latest 50 events
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8080/api/events?limit=50"

# 2. Load more - get 20 older events using cursor
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8080/api/events?after_ts=<ts>>&after_id=<event_uuid>"

# 3. Refresh - get 20 newer events
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8080/api/events?before_ts=<ts>>&before_id=<event_uuid>"
```

## Generating Sample Log Files

Use the provided script to generate sample log files for testing:

```bash
cd backend
./scripts/generate_file.sh [size_in_mb]

# Examples:
./scripts/generate_file.sh 2    # Generate 2MB file (default)
./scripts/generate_file.sh 5    # Generate 5MB file
./scripts/generate_file.sh 10   # Generate 10MB file
```

Generated files are placed in the `files/` directory and can be referenced by events via the `download_url` field.