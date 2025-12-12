package middleware

import (
	"ioteventfeed/backend/auth"
	"ioteventfeed/backend/models"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware validates JWT tokens
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Unauthorized",
				Code:  http.StatusUnauthorized,
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error: "Invalid authorization header format",
				Code:  http.StatusUnauthorized,
			})
			c.Abort()
			return
		}

		tokenString := parts[1]
		claims, err := auth.ValidateToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Invalid token",
				Message: err.Error(),
				Code:    http.StatusUnauthorized,
			})
			c.Abort()
			return
		}

		// Store user info in context
		// These values are request-scoped and safe - each request gets its own context instance
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)

		c.Next()
	}
}
