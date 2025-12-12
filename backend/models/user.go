package models

type User struct {
	ID           string `json:"id"` // UUID
	Username     string `json:"username"`
	Email        string `json:"email"`
	Name         string `json:"name"`
	Role         string `json:"role"`
	PasswordHash string `json:"-"` // Never serialize password hash to JSON
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}
