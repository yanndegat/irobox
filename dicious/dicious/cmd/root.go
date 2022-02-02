package cmd

import (
	"dicious/pkg/events"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	broker             string
	notificationsTopic string
	resyncTopic        string
	group              string
	reset              string
	dbFile             string

	rootCmd = &cobra.Command{
		Use:   "dicious [options] kafka_host:kafka:port",
		Short: "dicious consumes ironic events from kafka",
		Long: `dicious consumes ironic notification events from kafka topics
and builds a global searchable DB of baremetal hosts and network devices.`,
		Args: cobra.ExactArgs(1),
		RunE: events.RunE,
	}
)

func init() {
	rootCmd.Flags().StringVarP(
		&notificationsTopic,
		events.NOTIFICATIONS_TOPIC,
		"n",
		events.DEFAULT_NOTIFICATIONS_TOPIC,
		"ironic notification events topic",
	)
	rootCmd.Flags().StringVarP(
		&resyncTopic,
		events.RESYNC_TOPIC,
		"r",
		events.DEFAULT_RESYNC_TOPIC,
		"ironic resync db topic",
	)
	rootCmd.Flags().StringVarP(
		&group,
		events.GROUP,
		"g",
		events.DEFAULT_GROUP,
		"kafka consumer group",
	)
	rootCmd.Flags().StringVarP(
		&reset,
		events.OFFSET_RESET,
		"o",
		events.DEFAULT_OFFSET_RESET,
		"kafka auto offset reset",
	)
	rootCmd.Flags().StringVarP(
		&dbFile,
		events.DB_FILE,
		"d",
		events.DEFAULT_DB_FILE,
		"sqlite db file path",
	)

	viper.BindPFlag(events.NOTIFICATIONS_TOPIC, rootCmd.Flags().Lookup(events.NOTIFICATIONS_TOPIC))
	viper.BindPFlag(events.RESYNC_TOPIC, rootCmd.Flags().Lookup(events.RESYNC_TOPIC))
	viper.BindPFlag(events.GROUP, rootCmd.Flags().Lookup(events.GROUP))
	viper.BindPFlag(events.OFFSET_RESET, rootCmd.Flags().Lookup(events.OFFSET_RESET))
	viper.BindPFlag(events.DB_FILE, rootCmd.Flags().Lookup(events.DB_FILE))
}

func Execute() error {
	return rootCmd.Execute()
}
