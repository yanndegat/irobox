package events

import (
	"time"

	"dicious/pkg/repository"
)

func handleResync(repo *repository.SQLiteRepository, msg []byte, t time.Time) error {
	return nil
}
