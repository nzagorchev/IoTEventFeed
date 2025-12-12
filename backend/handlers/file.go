package handlers

import (
	"fmt"
	"ioteventfeed/backend/models"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

// FileHandler handles file download requests
type FileHandler struct {
	filesDir string
}

func NewFileHandler(filesDir string) *FileHandler {
	// Ensure files directory exists
	os.MkdirAll(filesDir, 0755)
	return &FileHandler{filesDir: filesDir}
}

func (h *FileHandler) DownloadFile(c *gin.Context) {
	filename := c.Param("filename")

	log.Printf("File download request - filename: %s, user: %s", filename)

	// Security: prevent directory traversal
	if filepath.Base(filename) != filename {
		log.Printf("File download failed: invalid filename - filename: %s", filename)
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid filename",
			Message: "Filename contains invalid characters",
			Code:    http.StatusBadRequest,
		})
		return
	}

	filePath := filepath.Join(h.filesDir, filename)

	// Check if file exists
	fileInfo, err := os.Stat(filePath)
	if os.IsNotExist(err) {
		log.Printf("File download failed: file not found - filename: %s", filename)
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "File not found",
			Message: "The requested file does not exist",
			Code:    http.StatusNotFound,
		})
		return
	}

	if err != nil {
		log.Printf("File download failed: stat error - filename: %s, error: %v", filename, err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Internal server error",
			Message: "Failed to access file",
			Code:    http.StatusInternalServerError,
		})
		return
	}

	// Open file
	file, err := os.Open(filePath)
	if err != nil {
		log.Printf("File download failed: open error - filename: %s, user: %s, error: %v", filename, err)
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Internal server error",
			Message: "Failed to open file",
			Code:    http.StatusInternalServerError,
		})
		return
	}
	defer file.Close()

	log.Printf("File download started - filename: %s, size: %d bytes", filename, fileInfo.Size())

	// Set headers for file download
	c.Header("Content-Description", "File Transfer")
	c.Header("Content-Transfer-Encoding", "binary")
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Header("Content-Type", "application/octet-stream")
	c.Header("Content-Length", fmt.Sprintf("%d", fileInfo.Size()))

	// Stream file to response
	c.DataFromReader(http.StatusOK, fileInfo.Size(), "application/octet-stream", file, nil)

	log.Printf("File download completed - filename: %s", filename)
}
