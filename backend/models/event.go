package models

import (
	"encoding/json"
	"time"
)

// Event represents an IoT device event
type Event struct {
	ID          string    `json:"id"` // UUID
	DeviceID    string    `json:"device_id"`
	DeviceName  string    `json:"device_name"`
	Type        string    `json:"type"`
	Severity    string    `json:"severity"`
	Message     string    `json:"message"`
	Timestamp   time.Time `json:"timestamp"` // Serialized as Unix milliseconds
	Location    string    `json:"location"`
	DownloadURL *string   `json:"download_url,omitempty"` // Optional download link for log files
}

// MarshalJSON customizes JSON serialization to output timestamp as Unix milliseconds
func (e Event) MarshalJSON() ([]byte, error) {
	type Alias Event
	return json.Marshal(&struct {
		Timestamp int64 `json:"timestamp"`
		*Alias
	}{
		Timestamp: e.Timestamp.UnixMilli(),
		Alias:     (*Alias)(&e),
	})
}

// UnmarshalJSON customizes JSON deserialization to parse timestamp from Unix milliseconds
func (e *Event) UnmarshalJSON(data []byte) error {
	type Alias Event
	aux := &struct {
		Timestamp int64 `json:"timestamp"`
		*Alias
	}{
		Alias: (*Alias)(e),
	}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	e.Timestamp = time.UnixMilli(aux.Timestamp)
	return nil
}

// EventListResponse represents a paginated list of events
type EventListResponse struct {
	Events    []Event `json:"events"`
	HasNext   bool    `json:"has_next"`              // Whether there are more events available
	NextCursor *Cursor `json:"next_cursor,omitempty"` // Cursor for fetching next page (older events)
}

// Cursor represents a pagination cursor (timestamp + event ID)
type Cursor struct {
	Timestamp int64  `json:"timestamp"` // Unix milliseconds
	EventID   string `json:"event_id"`   // UUID
}

// NewEventsCountResponse represents the count of new events
type NewEventsCountResponse struct {
	TotalCount    int `json:"total_count"`     // Total count of new events
	CriticalCount int `json:"critical_count"`  // Count of critical events among new events
}
