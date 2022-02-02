package main

import (
	"log"
	"os"

	"dicious/cmd"
	"dicious/pkg/logging"
)

const (
	// The parent process will create a file to collect crash logs
	envTmpLogPath = "TGVARS_TEMP_LOG_PATH"
)

func main() {
	os.Exit(realMain())
}

func realMain() int {
	defer logging.PanicHandler()
	log.Printf("[DEBUG] dicious called with args: %v", os.Args)

	tmpLogPath := os.Getenv(envTmpLogPath)
	if tmpLogPath != "" {
		f, err := os.OpenFile(tmpLogPath, os.O_RDWR|os.O_APPEND, 0666)
		if err == nil {
			defer f.Close()

			log.Printf("[DEBUG] Adding temp file log sink: %s", f.Name())
			logging.RegisterSink(f)
		} else {
			log.Printf("[ERROR] Could not open temp log file: %v", err)
		}
	}

	if err := cmd.Execute(); err != nil {
		log.Printf("[ERROR] Failed: %v", err)
		return -1
	}

	return 0
}
