package auth

import (
	"golang.org/x/crypto/bcrypt"
)

const (
	// Cost factor for bcrypt hashing
	// Higher cost = more secure but slower
	BcryptCost = 10
)

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), BcryptCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
