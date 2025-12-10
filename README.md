# IoT Event feed

This project represents a lightweight platform to show IoT device events.

The project includes:
- A **lightweight backend** service providing event APIs and authentication.
- An **iOS application** that displays an event feed and supports offline usage.

## Features

### iOS App

- Login
- Profile Details
- Event Feed 
    - List of events, pagination
    - Refresh
    - Handling of loading / empty / error states
- Event Details
- Offline Support - cache data locally

### Backend

- RESTful API built with Go and Gin framework
- JWT authentication with bcrypt password hashing
- Event management with cursor-based pagination
- File download endpoints for log files
- In-memory mock store with thread-safe operations

For detailed backend documentation, see [Backend README](backend/README.md).

## 🛠 Technologies

- iOS: Swift (iOS 17+)
- Backend: Go 1.24+ with Gin framework, JWT authentication

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

Instructions for running the iOS app will be added once the implementation is complete.

## 📄 Notes

This README will be expanded as the project evolves.