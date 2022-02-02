package repository

import (
	"database/sql"
)

const (
	hosts_schema = `
    CREATE TABLE IF NOT EXISTS hosts(
        id TEST PRIMARY KEY,
        name TEXT,
        rack_id TEXT,
        resource_class TEXT,
        power_state TEXT,
        provision_state TEXT
    );
    `
)

type Host struct {
	Id                string
	Name              string
	RackId            string
	ResourceClass     string
	PowerState        string
	ProvisionState string
}

func initHosts(db *sql.DB) error {
	_, err := db.Exec(hosts_schema)
	return err
}

func (h *Host) Add(db *sql.DB) (sql.Result, error) {
	return db.Exec(`
        INSERT INTO hosts(id, name, rack_id, resource_class, power_state, provision_state)
        VALUES (:id,:name,:rack,:class,:power,:prov)
        ON CONFLICT(id) DO UPDATE SET
          name = :name,
          rack_id = :rack,
          resource_class = :class,
          power_state = :power,
          provision_state = :prov
        WHERE id = :id
        `,
		sql.Named("id", h.Id),
		sql.Named("name", h.Name),
		sql.Named("rack", h.RackId),
		sql.Named("class", h.ResourceClass),
		sql.Named("power", h.PowerState),
		sql.Named("prov", h.ProvisionState),
	)
}

func (h *Host) Remove(db *sql.DB) (sql.Result, error) {
	return db.Exec("DELETE FROM hosts where id = ?", h.Id)
}

func (h *Host) All(db *sql.DB) (*sql.Rows, error) {
	return db.Query("Select * FROM hosts")
}

func (h *Host) Scan(rows *sql.Rows) (*Host, error) {
	var host Host
	if err := rows.Scan(&host.Id, &host.Name); err != nil {
		return nil, err
	}
	return &host, nil
}
