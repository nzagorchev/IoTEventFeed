package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"ioteventfeed/backend/handlers"
	"ioteventfeed/backend/routes"
	"ioteventfeed/backend/store"
)

func main() {
	// Parse command line flags
	port := flag.String("port", "8080", "Port to run the server on")
	flag.Parse()

	// Initialize store with mock data
	mockStore := store.NewMockStore()

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(mockStore)
	userHandler := handlers.NewUserHandler(mockStore)
	eventHandler := handlers.NewEventHandler(mockStore)

	// Setup routes
	router := routes.SetupRoutes(authHandler, userHandler, eventHandler)

	// Disable Trusted Proxies - change in production if this should be handled on gin level
	router.SetTrustedProxies(nil)

	// Start server
	addr := fmt.Sprintf(":%s", *port)
	log.Printf("Server starting on port %s", *port)
	log.Printf("API endpoints available at http://localhost%s/api", addr)
	log.Println("\nAvailable endpoints:")
	log.Println("  POST   /api/login")
	log.Println("  GET    /api/user/:id")
	log.Println("  GET    /api/events?page=1&page_size=20")
	log.Println("  GET    /api/events/:id")
	log.Println("\nHardcoded users:")
	log.Println("  - admin / admin123")
	log.Println("  - user1 / password123")
	log.Println("  - demo / demo123")

	if err := router.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
		os.Exit(1)
	}
}
