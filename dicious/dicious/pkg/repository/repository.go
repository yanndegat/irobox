package repository

import (
	"database/sql"
	"errors"
	"fmt"
	"log"

	"github.com/mattn/go-sqlite3"
)

var (
	ErrDuplicate    = errors.New("record already exists")
	ErrNotExists    = errors.New("row not exists")
	ErrUpdateFailed = errors.New("update failed")
	ErrDeleteFailed = errors.New("delete failed")
)

type SQLiteRepository struct {
	db *sql.DB
}

type DBEntity[T any] interface {
	Add(*sql.DB) (sql.Result, error)
	Remove(*sql.DB) (sql.Result, error)
	All(*sql.DB) (*sql.Rows, error)
	Scan(*sql.Rows) (*T, error)
}

func NewSQLiteRepository(fileName string) (*SQLiteRepository, error) {
	log.Printf("[DEBUG] opening db %s", fileName)
	db, err := sql.Open("sqlite3", fileName)
	if err != nil {
		return nil, err
	}

	if err := initHosts(db); err != nil {
		return nil, fmt.Errorf("Could not init hosts: %v", err)
	}

	return  &SQLiteRepository{ db: db }, nil
}

func Add[T any, E DBEntity[T]](r *SQLiteRepository, e E) error {
	_, err := e.Add(r.db)
	if err != nil {
		var sqliteErr sqlite3.Error
		if errors.As(err, &sqliteErr) {
			if errors.Is(sqliteErr.ExtendedCode, sqlite3.ErrConstraintUnique) {
				return ErrDuplicate
			}
		}
		return err
	}

	return nil
}

func All[T any, E DBEntity[T]](r *SQLiteRepository) ([]*T, error) {
	var e E
	rows, err := e.All(r.db)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var all []*T
	for rows.Next() {
		entity, err := e.Scan(rows)
		if err != nil {
			return nil, err
		}
		all = append(all, entity)
	}
	return all, nil
}

func Remove[T any, E DBEntity[T]](r *SQLiteRepository, e E) error {
	res, err := e.Remove(r.db)
	if err != nil {
		return err
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return ErrDeleteFailed
	}

	return err
}
