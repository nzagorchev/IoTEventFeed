package middleware

import (
	"errors"

	"github.com/gin-gonic/gin"
)

var (
	ErrUserIDNotFound = errors.New("user ID not found in context")
	ErrInvalidUserID  = errors.New("invalid user ID type in context")
)

// GetUserID safely extracts the user ID (UUID) from the Gin context
// Returns an error if the user ID is not present or has an invalid type
func GetUserID(c *gin.Context) (string, error) {
	userID, exists := c.Get("user_id")
	if !exists {
		return "", ErrUserIDNotFound
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return "", ErrInvalidUserID
	}

	return userIDStr, nil
}

func GetUsername(c *gin.Context) (string, error) {
	username, exists := c.Get("username")
	if !exists {
		return "", ErrUserIDNotFound
	}

	usernameStr, ok := username.(string)
	if !ok {
		return "", ErrInvalidUserID
	}

	return usernameStr, nil
}
