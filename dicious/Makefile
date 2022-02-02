.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: .env
.env:
	@$(MAKE) -C .. dicious-env

.PHONY: up
up: .env ## up dicious
	@docker-compose \
	-f docker-compose.yml \
	up -d

.PHONY: down
down: .env ## down dicious
	@docker-compose \
	-f docker-compose.yml \
	down --remove-orphans


.PHONY: clean
clean: .env ## clean dicious volumes
	@docker volume rm dicious_dicious-db dicious_zookeeper dicious_kafka || true
