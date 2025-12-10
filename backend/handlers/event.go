package handlers

import (
	"ioteventfeed/backend/models"
	"ioteventfeed/backend/store"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type EventHandler struct {
	store *store.MockStore
}

func NewEventHandler(s *store.MockStore) *EventHandler {
	return &EventHandler{store: s}
}

// GetEvents retrieves a paginated list of events
// Query parameters:
//   - limit: Maximum number of events (for latest events, no cursor) - default: 20, max: 100
//   - before_ts: Timestamp to get newer events (for refresh) - Unix milliseconds
//   - before_id: Event ID for precise filtering with before_ts (optional)
//   - after_ts: Timestamp to get older events (for backward pagination) - Unix milliseconds
//   - after_id: Event ID for precise filtering with after_ts (optional)
//
// Events are always sorted by timestamp in descending order (newest first)
// When using before_ts or after_ts, page size is fixed at 20 events
func (h *EventHandler) GetEvents(c *gin.Context) {
	var limit *int
	var beforeTS *time.Time
	var beforeID *string
	var afterTS *time.Time
	var afterID *string

	// Parse limit parameter (for latest events)
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			if l > 100 {
				l = 100 // Max limit
			}
			limit = &l
		} else {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Invalid limit format",
				Message: "The 'limit' parameter must be a positive integer (max: 100)",
				Code:    http.StatusBadRequest,
			})
			return
		}
	}

	// Parse before_ts parameter (for refresh - get newer events)
	if beforeTSStr := c.Query("before_ts"); beforeTSStr != "" {
		if timestampMs, err := strconv.ParseInt(beforeTSStr, 10, 64); err == nil {
			parsedTime := time.UnixMilli(timestampMs)
			beforeTS = &parsedTime

			// Parse optional before_id parameter
			if beforeIDStr := c.Query("before_id"); beforeIDStr != "" {
				beforeID = &beforeIDStr
			}
		} else {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Invalid timestamp format",
				Message: "The 'before_ts' parameter must be Unix milliseconds (e.g., 1705312200000)",
				Code:    http.StatusBadRequest,
			})
			return
		}
	} else {
		// If before_id is provided without before_ts, return error
		if beforeIDStr := c.Query("before_id"); beforeIDStr != "" {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Invalid parameter combination",
				Message: "The 'before_id' parameter requires the 'before_ts' parameter to be provided",
				Code:    http.StatusBadRequest,
			})
			return
		}
	}

	// Parse after_ts parameter (for backward pagination - get older events)
	if afterTSStr := c.Query("after_ts"); afterTSStr != "" {
		if timestampMs, err := strconv.ParseInt(afterTSStr, 10, 64); err == nil {
			parsedTime := time.UnixMilli(timestampMs)
			afterTS = &parsedTime

			// Parse optional after_id parameter
			if afterIDStr := c.Query("after_id"); afterIDStr != "" {
				afterID = &afterIDStr
			}
		} else {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Invalid timestamp format",
				Message: "The 'after_ts' parameter must be Unix milliseconds (e.g., 1705312200000)",
				Code:    http.StatusBadRequest,
			})
			return
		}
	} else {
		// If after_id is provided without after_ts, return error
		if afterIDStr := c.Query("after_id"); afterIDStr != "" {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Invalid parameter combination",
				Message: "The 'after_id' parameter requires the 'after_ts' parameter to be provided",
				Code:    http.StatusBadRequest,
			})
			return
		}
	}

	// Validate parameter combinations
	if beforeTS != nil && afterTS != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid parameter combination",
			Message: "Cannot use both 'before_ts' and 'after_ts' parameters together",
			Code:    http.StatusBadRequest,
		})
		return
	}

	// Set default limit if no cursor parameters provided
	if limit == nil && beforeTS == nil && afterTS == nil {
		defaultLimit := 20
		limit = &defaultLimit
	}

	events, hasNext := h.store.GetEvents(limit, beforeTS, beforeID, afterTS, afterID)

	response := models.EventListResponse{
		Events:  events,
		HasNext: hasNext,
	}

	// Generate next cursor if there are more events
	if hasNext && len(events) > 0 {
		lastEvent := events[len(events)-1]
		response.NextCursor = &models.Cursor{
			Timestamp: lastEvent.Timestamp.UnixMilli(),
			EventID:   lastEvent.ID,
		}
	}

	c.JSON(http.StatusOK, response)
}

func (h *EventHandler) GetEventByID(c *gin.Context) {
	eventID := c.Param("id")

	// Validate UUID format
	if eventID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid event ID",
			Message: "Event ID is required",
			Code:    http.StatusBadRequest,
		})
		return
	}

	event, exists := h.store.GetEventByID(eventID)
	if !exists {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "Event not found",
			Message: "The requested event does not exist",
			Code:    http.StatusNotFound,
		})
		return
	}

	c.JSON(http.StatusOK, event)
}
