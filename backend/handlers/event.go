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
//   - page: Page number (default: 1)
//   - page_size: Items per page (default: 20, max: 100)
//   - after: Timestamp to filter events after this time (optional)
//   - after_id: Event Id for more precise filtering (optional)
//
// Events are always sorted by timestamp in descending order (newest first)
func (h *EventHandler) GetEvents(c *gin.Context) {
	// Parse pagination parameters
	page := 1
	pageSize := 20

	if pageStr := c.Query("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	if pageSizeStr := c.Query("page_size"); pageSizeStr != "" {
		if ps, err := strconv.Atoi(pageSizeStr); err == nil && ps > 0 && ps <= 100 {
			pageSize = ps
		}
	}

	// Parse after timestamp parameter (Unix milliseconds)
	var after *time.Time
	var afterID *string

	if afterStr := c.Query("after"); afterStr != "" {
		// Try parsing as Unix milliseconds (int64)
		if timestampMs, err := strconv.ParseInt(afterStr, 10, 64); err == nil {
			parsedTime := time.UnixMilli(timestampMs)
			after = &parsedTime
		} else {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "Invalid timestamp format",
				Message: "The 'after' parameter must be Unix milliseconds (e.g., 1705312200000)",
				Code:    http.StatusBadRequest,
			})
			return
		}

		// Parse optional after_id parameter for more precise filtering
		if afterIDStr := c.Query("after_id"); afterIDStr != "" {
			afterID = &afterIDStr
		}
	}

	events, total, hasMore := h.store.GetEvents(page, pageSize, after, afterID)

	response := models.EventListResponse{
		Events:   events,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
		HasMore:  hasMore,
	}

	if hasMore {
		nextPage := page + 1
		response.NextPage = &nextPage
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
