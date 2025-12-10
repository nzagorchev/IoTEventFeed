package store

import (
	"fmt"
	"ioteventfeed/backend/auth"
	"ioteventfeed/backend/models"
	"log"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// MockStore provides in-memory storage for the application
type MockStore struct {
	users  map[string]*models.User
	events []models.Event
	mu     sync.RWMutex
}

func NewMockStore() *MockStore {
	store := &MockStore{
		users:  make(map[string]*models.User),
		events: make([]models.Event, 0),
	}

	// Get list of available log files from files directory
	availableLogFiles := getAvailableLogFiles("./files")

	// Initialize hardcoded users with hashed passwords
	// Default passwords:
	// - admin: admin123
	// - user1: password123
	// - demo: demo123

	adminHash, err := auth.HashPassword("admin123")
	if err != nil {
		log.Fatalf("Failed to hash admin password: %v", err)
	}
	store.users["admin"] = &models.User{
		ID:           uuid.New().String(),
		Username:     "admin",
		Email:        "admin@ioteventfeed.com",
		Name:         "Admin User",
		Role:         "administrator",
		PasswordHash: adminHash,
	}

	user1Hash, err := auth.HashPassword("password123")
	if err != nil {
		log.Fatalf("Failed to hash user1 password: %v", err)
	}
	store.users["user1"] = &models.User{
		ID:           uuid.New().String(),
		Username:     "user1",
		Email:        "user1@ioteventfeed.com",
		Name:         "John Doe",
		Role:         "user",
		PasswordHash: user1Hash,
	}

	demoHash, err := auth.HashPassword("demo123")
	if err != nil {
		log.Fatalf("Failed to hash demo password: %v", err)
	}
	store.users["demo"] = &models.User{
		ID:           uuid.New().String(),
		Username:     "demo",
		Email:        "demo@ioteventfeed.com",
		Name:         "Demo User",
		Role:         "user",
		PasswordHash: demoHash,
	}

	// Initialize IoT events
	// Use time.Now() which has nanosecond precision, ensuring millisecond precision when converted
	now := time.Now()
	store.events = []models.Event{
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-001",
			DeviceName: "Device - Main Entrance",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-5 * time.Minute),
			Location:   "Main Entrance, Building A",
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-002",
			DeviceName: "Device - Server Room Access",
			Type:       "facial_authentication",
			Severity:   "warning",
			Message:    "Facial authentication failed",
			Timestamp:  now.Add(-12 * time.Minute),
			Location:   "Server Room, Floor 3",
		},
		{
			ID:          uuid.New().String(),
			DeviceID:    "DEVICE-001",
			DeviceName:  "Device - Main Entrance",
			Type:        "tailgating_detection",
			Severity:    "critical",
			Message:     "Tailgating detected - Unauthorized person followed authorized user",
			Timestamp:   now.Add(-18 * time.Minute),
			Location:    "Main Entrance, Building A",
			DownloadURL: getLogFileURL(availableLogFiles, 1),
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-003",
			DeviceName: "Device - Executive Floor",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-25 * time.Minute),
			Location:   "Executive Floor, Building B",
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-002",
			DeviceName: "Device - Server Room Access",
			Type:       "access_denied",
			Severity:   "warning",
			Message:    "Access denied - Authentication failure after 3 attempts",
			Timestamp:  now.Add(-32 * time.Minute),
			Location:   "Server Room, Floor 3",
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-004",
			DeviceName: "Device - Parking Garage",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-45 * time.Minute),
			Location:   "Parking Garage, Level 2",
		},
		{
			ID:          uuid.New().String(),
			DeviceID:    "DEVICE-001",
			DeviceName:  "Device - Main Entrance",
			Type:        "tailgating_detection",
			Severity:    "critical",
			Message:     "Tailgating detected - Multiple unauthorized individuals",
			Timestamp:   now.Add(-1 * time.Hour),
			Location:    "Main Entrance, Building A",
			DownloadURL: getLogFileURL(availableLogFiles, 2),
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-005",
			DeviceName: "Device - Research Lab",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-1*time.Hour + 15*time.Minute),
			Location:   "Research Lab, Building C",
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-003",
			DeviceName: "Device - Executive Floor",
			Type:       "access_denied",
			Severity:   "error",
			Message:    "Access denied - Face mask detected, authentication required",
			Timestamp:  now.Add(-1*time.Hour + 30*time.Minute),
			Location:   "Executive Floor, Building B",
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-006",
			DeviceName: "Device - Data Center",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-2 * time.Hour),
			Location:   "Data Center, Basement",
		},
		{
			ID:          uuid.New().String(),
			DeviceID:    "DEVICE-002",
			DeviceName:  "Device - Server Room Access",
			Type:        "system",
			Severity:    "error",
			Message:     "System error - Camera calibration required",
			Timestamp:   now.Add(-2*time.Hour + 20*time.Minute),
			Location:    "Server Room, Floor 3",
			DownloadURL: getLogFileURL(availableLogFiles, 0),
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-001",
			DeviceName: "Device - Main Entrance",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-3 * time.Hour),
			Location:   "Main Entrance, Building A",
		},
		{
			ID:          uuid.New().String(),
			DeviceID:    "DEVICE-004",
			DeviceName:  "Device - Parking Garage",
			Type:        "tailgating_detection",
			Severity:    "critical",
			Message:     "Tailgating detected - Vehicle tailgating through gate",
			Timestamp:   now.Add(-3*time.Hour + 30*time.Minute),
			Location:    "Parking Garage, Level 2",
			DownloadURL: getLogFileURL(availableLogFiles, 3),
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-007",
			DeviceName: "Device - Warehouse Entrance",
			Type:       "facial_authentication",
			Severity:   "warning",
			Message:    "Facial authentication failed - Low confidence match",
			Timestamp:  now.Add(-4 * time.Hour),
			Location:   "Warehouse Entrance, Building D",
		},
		{
			ID:         uuid.New().String(),
			DeviceID:   "DEVICE-005",
			DeviceName: "Device - Research Lab",
			Type:       "facial_authentication",
			Severity:   "info",
			Message:    "Facial authentication successful",
			Timestamp:  now.Add(-4*time.Hour + 45*time.Minute),
			Location:   "Research Lab, Building C",
		},
	}

	// Add more events to demonstrate pagination
	locations := []string{"Main Entrance, Building A", "Server Room, Floor 3", "Executive Floor, Building B",
		"Parking Garage, Level 2", "Research Lab, Building C", "Data Center, Basement",
		"Warehouse Entrance, Building D", "Conference Room, Floor 5", "IT Office, Floor 2", "Lobby, Building A"}
	deviceIDs := []string{"DEVICE-001", "DEVICE-002", "DEVICE-003", "DEVICE-004", "DEVICE-005",
		"DEVICE-006", "DEVICE-007", "DEVICE-008", "DEVICE-009", "DEVICE-010"}
	deviceNames := []string{"Device - Main Entrance", "Device - Server Room Access", "Device - Executive Floor",
		"Device - Parking Garage", "Device - Research Lab", "Device - Data Center",
		"Device - Warehouse Entrance", "Device - Conference Room", "Device - IT Office", "Device - Lobby"}
	eventTypes := []string{"facial_authentication", "tailgating_detection", "access_denied", "facial_authentication",
		"facial_authentication", "tailgating_detection", "access_denied", "facial_authentication",
		"facial_authentication", "tailgating_detection"}
	severities := []string{"info", "critical", "warning", "info", "info", "critical", "warning", "info", "info", "critical"}
	messages := []string{
		"Facial authentication successful",
		"Tailgating detected",
		"Access denied - Authentication failure",
		"Facial authentication successful",
		"Facial authentication successful",
		"Tailgating detected",
		"Access denied",
		"Facial authentication successful",
		"Facial authentication successful",
		"Tailgating detected",
	}

	for i := 16; i <= 50; i++ {
		idx := i % 10
		hoursAgo := i / 2         // Spread events over time
		minutesOffset := (i % 60) // Add minute-level variation

		severity := severities[idx]
		var downloadURL *string
		// Only assign download URLs if log files are available
		if len(availableLogFiles) > 0 {
			if i%7 == 0 {
				severity = "error" // Occasional system errors
				// Add download URL for system errors (cycle through available files)
				downloadURL = getLogFileURL(availableLogFiles, (i/7)%len(availableLogFiles))
			} else if eventTypes[idx] == "tailgating_detection" && i%3 == 0 {
				// Add download URL for some tailgating events
				downloadURL = getLogFileURL(availableLogFiles, (i/3)%len(availableLogFiles))
			}
		}

		store.events = append(store.events, models.Event{
			ID:          uuid.New().String(),
			DeviceID:    deviceIDs[idx],
			DeviceName:  deviceNames[idx],
			Type:        eventTypes[idx],
			Severity:    severity,
			Message:     fmt.Sprintf("%s - Event #%d", messages[idx], i),
			Timestamp:   now.Add(-time.Duration(hoursAgo)*time.Hour - time.Duration(minutesOffset)*time.Minute),
			Location:    locations[idx],
			DownloadURL: downloadURL,
		})
	}

	return store
}

func (s *MockStore) GetUserByUsername(username string) (*models.User, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	user, exists := s.users[username]
	return user, exists
}

func (s *MockStore) GetUserByID(id string) (*models.User, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, user := range s.users {
		if user.ID == id {
			return user, true
		}
	}
	return nil, false
}

// GetEvents retrieves events with cursor-based pagination
// Events are always sorted by timestamp in descending order (newest first)
//
// Parameters:
//   - limit: Maximum number of events to return (for latest events, no cursor)
//   - beforeTS: Get events newer than this timestamp (for refresh)
//   - beforeID: Event ID for precise filtering with beforeTS
//   - afterTS: Get events older than this timestamp (for backward pagination)
//   - afterID: Event ID for precise filtering with afterTS
//
// Returns: (events, hasNext)
func (s *MockStore) GetEvents(limit *int, beforeTS *time.Time, beforeID *string, afterTS *time.Time, afterID *string) ([]models.Event, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Start with all events
	filteredEvents := s.events

	// Filter by beforeTS (for refresh - get newer events)
	// Events with timestamp > beforeTS (newer than beforeTS)
	if beforeTS != nil {
		temp := make([]models.Event, 0)
		for _, event := range filteredEvents {
			if event.Timestamp.After(*beforeTS) {
				temp = append(temp, event)
			}
		}
		filteredEvents = temp
	}

	// Filter by afterTS (for backward pagination - get older events)
	// Events with timestamp < afterTS (older than afterTS)
	if afterTS != nil {
		temp := make([]models.Event, 0)
		for _, event := range filteredEvents {
			if event.Timestamp.Before(*afterTS) {
				temp = append(temp, event)
			}
		}
		filteredEvents = temp
	}

	// Sort events by timestamp descending, then by ID descending for deterministic ordering
	sortedEvents := make([]models.Event, len(filteredEvents))
	copy(sortedEvents, filteredEvents)
	sort.Slice(sortedEvents, func(i, j int) bool {
		if sortedEvents[i].Timestamp.Equal(sortedEvents[j].Timestamp) {
			// Deterministic tie-breaker: sort by ID descending
			return sortedEvents[i].ID > sortedEvents[j].ID
		}
		return sortedEvents[i].Timestamp.After(sortedEvents[j].Timestamp)
	})

	// Apply ID-based filtering for precise cursor positioning
	if beforeID != nil && beforeTS != nil {
		// Find the position of the event with beforeID in the sorted list
		foundIndex := -1
		for i, event := range sortedEvents {
			if event.ID == *beforeID {
				foundIndex = i
				break
			}
		}

		if foundIndex >= 0 {
			// Return only events that come after the found event (exclude the event itself)
			sortedEvents = sortedEvents[foundIndex+1:]
		} else {
			// If beforeID not found, return empty
			sortedEvents = []models.Event{}
		}
	}

	if afterID != nil && afterTS != nil {
		// Find the position of the event with afterID in the sorted list
		foundIndex := -1
		for i, event := range sortedEvents {
			if event.ID == *afterID {
				foundIndex = i
				break
			}
		}

		if foundIndex >= 0 {
			// Return only events that come after the found event (exclude the event itself)
			// Since events are sorted descending (newest first), older events come AFTER in the list
			// So we take events after the cursor event index
			sortedEvents = sortedEvents[foundIndex+1:]
		} else {
			// If afterID not found, return empty
			sortedEvents = []models.Event{}
		}
	}

	// Determine page size
	pageSize := 20 // Fixed size for cursor-based pagination
	if limit != nil && beforeTS == nil && afterTS == nil {
		// Use limit only for latest events (no cursor)
		pageSize = *limit
		if pageSize > 100 {
			pageSize = 100 // Max limit
		}
	}

	// Apply pagination
	total := len(sortedEvents)
	if total == 0 {
		return []models.Event{}, false
	}

	if pageSize > total {
		pageSize = total
	}

	events := sortedEvents[:pageSize]
	hasNext := pageSize < total

	return events, hasNext
}

func (s *MockStore) GetEventByID(id string) (*models.Event, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, event := range s.events {
		if event.ID == id {
			return &event, true
		}
	}
	return nil, false
}

func getAvailableLogFiles(filesDir string) []string {
	files := []string{}

	if _, err := os.Stat(filesDir); os.IsNotExist(err) {
		return files
	}

	entries, err := os.ReadDir(filesDir)
	if err != nil {
		return files
	}

	// Filter for system_log_*.txt files
	for _, entry := range entries {
		if !entry.IsDir() && strings.HasPrefix(entry.Name(), "system_log_") && strings.HasSuffix(entry.Name(), ".txt") {
			files = append(files, entry.Name())
		}
	}

	return files
}

// getLogFileURL returns a download URL for a log file, or nil if no files available
func getLogFileURL(availableFiles []string, index int) *string {
	if len(availableFiles) == 0 {
		return nil
	}

	// Cycle through available files
	fileIndex := index % len(availableFiles)
	filename := availableFiles[fileIndex]
	url := fmt.Sprintf("/api/files/%s", filename)
	return &url
}
