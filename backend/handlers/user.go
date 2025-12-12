package handlers

import (
	"ioteventfeed/backend/middleware"
	"ioteventfeed/backend/models"
	"ioteventfeed/backend/store"
	"net/http"

	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	store *store.MockStore
}

func NewUserHandler(s *store.MockStore) *UserHandler {
	return &UserHandler{store: s}
}

// GetUserProfile retrieves user profile by ID (UUID)
func (h *UserHandler) GetUserProfile(c *gin.Context) {
	userID := c.Param("id")

	// Validate UUID format
	if userID == "" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid user ID",
			Message: "User ID is required",
			Code:    http.StatusBadRequest,
		})
		return
	}

	// Get authenticated user ID from context
	// Context is request-scoped, so this is safe - each request has its own isolated context
	authUserID, err := middleware.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error: "Unauthorized",
			Code:  http.StatusUnauthorized,
		})
		return
	}

	// Users can only view their own profile
	if authUserID != userID {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "Forbidden",
			Message: "You can only view your own profile",
			Code:    http.StatusForbidden,
		})
		return
	}

	user, exists := h.store.GetUserByID(userID)
	if !exists {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "User not found",
			Message: "The requested user does not exist",
			Code:    http.StatusNotFound,
		})
		return
	}

	c.JSON(http.StatusOK, user)
}
