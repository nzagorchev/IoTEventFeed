package handlers

import (
	"ioteventfeed/backend/auth"
	"ioteventfeed/backend/models"
	"ioteventfeed/backend/store"
	"net/http"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	store *store.MockStore
}

func NewAuthHandler(s *store.MockStore) *AuthHandler {
	return &AuthHandler{store: s}
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
			Code:    http.StatusBadRequest,
		})
		return
	}

	invalidCredentialsResponse := models.ErrorResponse{
		Error:   "Invalid credentials",
		Message: "Username or password is incorrect",
		Code:    http.StatusUnauthorized,
	}

	// Find user by username
	user, exists := h.store.GetUserByUsername(req.Username)
	if !exists {
		c.JSON(http.StatusUnauthorized, invalidCredentialsResponse)
		return
	}

	// Verify password against stored hash
	if !auth.CheckPassword(req.Password, user.PasswordHash) {
		c.JSON(http.StatusUnauthorized, invalidCredentialsResponse)
		return
	}

	// Generate JWT token
	token, err := auth.GenerateToken(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Internal server error",
			Message: "Failed to generate token",
			Code:    http.StatusInternalServerError,
		})
		return
	}

	c.JSON(http.StatusOK, models.LoginResponse{
		Token: token,
		User:  *user,
	})
}
