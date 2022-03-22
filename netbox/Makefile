.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: .env
.env:
	@$(MAKE) -C .. netbox-env

conf:
# netxbox_onboarding plugin is not supported by netbox >= 3.0
#	@sed -i -e 's/^PLUGINS = \[\]/PLUGINS = ["netbox_onboarding"]/' netbox/configuration/configuration.py

.PHONY: build
build: conf .env ## up netbox
	@docker-compose \
	--project-directory netbox \
	-f netbox/docker-compose.yml \
	-f docker-compose.override-netbox.yml \
	build

.PHONY: up
up: conf .env ## up netbox
	@docker-compose \
	--project-directory netbox \
	-f netbox/docker-compose.yml \
	-f docker-compose.override-netbox.yml \
	up -d

.PHONY: down
down: .env ## down netbox
	@docker-compose \
	--project-directory netbox \
	-f netbox/docker-compose.yml \
	-f docker-compose.override-netbox.yml \
	down --remove-orphans

.PHONY: clean
netbox-clean: ## clean netbox volumes
	@docker volume rm  netbox_netbox-media-files_1 netbox_netbox-postgres-data_1 netbox_netbox-redis-data_1
