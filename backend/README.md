# IoT Event Feed Backend

A lightweight backend service built with Go and Gin framework that provides APIs for authentication, event management, and file downloads for an IoT event monitoring system.

## Architecture

### Technology Stack
- **Language**: Go 1.24+
- **Framework**: Gin (HTTP web framework)
- **Authentication**: JWT (JSON Web Tokens)
- **Storage**: In-memory mock store

### Architecture Decisions

1. **RESTful API Design**: Clean REST endpoints following standard conventions
2. **JWT Authentication**: Stateless authentication using JWT tokens for scalability
3. **In-Memory Storage**: Mock store for simplicity
4. **Layered Architecture**: Separation of concerns with handlers, models, middleware, and routes
5. **Error Handling**: Consistent error response format across all endpoints

### Project Structure

```
backend/
├── main.go              # Application entry point
├── models/              # Data models
├── store/               # Data storage layer
│   └── mock_store.go
├── handlers/            # Request handlers
├── middleware/          # HTTP middleware
├── auth/                # Authentication utilities
└── routes/              # Route configuration
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