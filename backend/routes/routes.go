package routes

import (
	"ioteventfeed/backend/handlers"
	"ioteventfeed/backend/middleware"

	"github.com/gin-gonic/gin"
)

// SetupRoutes configures all application routes
func SetupRoutes(
	authHandler *handlers.AuthHandler,
	userHandler *handlers.UserHandler,
	eventHandler *handlers.EventHandler,
	fileHandler *handlers.FileHandler,
) *gin.Engine {
	router := gin.Default()

	// CORS middleware for iOS app
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Public routes
	api := router.Group("/api")
	{
		api.POST("/login", authHandler.Login)
	}

	// Protected routes (require authentication)
	protected := api.Group("")
	protected.Use(middleware.AuthMiddleware())
	{
		// User routes
		protected.GET("/user/:id", userHandler.GetUserProfile)

		// Event routes
		protected.GET("/events", eventHandler.GetEvents)
		protected.GET("/events/:id", eventHandler.GetEventByID)

		// File download routes
		protected.GET("/files/:filename", fileHandler.DownloadFile)
	}

	return router
}
