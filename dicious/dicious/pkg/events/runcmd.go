package events

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"dicious/pkg/repository"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const (
	NOTIFICATIONS_TOPIC = "notifications-topic"
	RESYNC_TOPIC        = "resync-topic"
	GROUP               = "group"
	OFFSET_RESET        = "offset-reset"
	DB_FILE             = "db-file"

	DEFAULT_NOTIFICATIONS_TOPIC = "notifications.info"
	DEFAULT_RESYNC_TOPIC        = "resync"
	DEFAULT_GROUP               = "dicious"
	DEFAULT_OFFSET_RESET        = "earliest"
	DEFAULT_DB_FILE             = "/var/lib/dicious.sqlite"
)

func RunE(cmd *cobra.Command, args []string) error {
	broker := args[0]
	notificationsTopic := viper.GetString(NOTIFICATIONS_TOPIC)
	resyncTopic := viper.GetString(RESYNC_TOPIC)
	group := viper.GetString(GROUP)
	reset := viper.GetString(OFFSET_RESET)
	dbFile := viper.GetString(DB_FILE)

	log.Printf("[INFO] Hello!")

	repo, err := repository.NewSQLiteRepository(dbFile)
	if err != nil {
		return err
	}

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": broker,
		"group.id":          group,
		"auto.offset.reset": reset,
	})

	if err != nil {
		return err
	}

	c.SubscribeTopics([]string{notificationsTopic, resyncTopic}, nil)

	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case sig := <-sigchan:
			log.Printf("[INFO] Caught signal %v: terminating", sig)
			break
		default:
			ev := c.Poll(100)
			if ev == nil {
				continue
			}

			switch e := ev.(type) {
			case *kafka.Message:
				err := handleMsg(repo, e)
				if err != nil {
					log.Printf("[ERROR] Error while handling msg: %v", err)
				}
			case kafka.Error:
				// Errors should generally be considered
				// informational, the client will try to
				// automatically recover.
				// But in this example we choose to terminate
				// the application if all brokers are down.
				log.Printf("[ERROR] Error: %v: %v", e.Code(), e)
				if e.Code() == kafka.ErrAllBrokersDown {
					break
				}
			default:
				log.Printf("[DEBUG] Ignored %v\n", e)
			}
		}
	}

	c.Close()
	return nil
}

func handleMsg(repo *repository.SQLiteRepository, m *kafka.Message) error {
	notificationsTopic := viper.GetString(NOTIFICATIONS_TOPIC)
	resyncTopic := viper.GetString(RESYNC_TOPIC)

	log.Printf("[TRACE] Message on %s:\n%s", m.TopicPartition, string(m.Value))
	if m.Headers != nil {
		log.Printf("[TRACE] Headers: %v", m.Headers)
	}

	if *m.TopicPartition.Topic == notificationsTopic {
		return handleNotification(repo, m.Value, m.Timestamp)
	}
	if *m.TopicPartition.Topic == resyncTopic {
		return handleResync(repo, m.Value, m.Timestamp)
	}

	return fmt.Errorf("unexpected topic %v from msg: %v", *m.TopicPartition.Topic, m)
}
