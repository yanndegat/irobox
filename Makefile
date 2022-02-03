.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: up
up: keystone-up glance-up horizon-up ironic-up neutron-up dicious-up ## up ironic & deps

.PHONY: down
down: keystone-down glance-down horizon-down ironic-down neutron-down  dicious-down ## down ironic & deps

.PHONY: clean
clean: keystone-clean glance-clean horizon-clean ironic-clean neutron-clean dicious-clean ## clean ironic & deps

./clouds.yaml: ironic-env
	@./clouds.yaml.sh

.PHONY: %-env
%-env: ## env subsystem
	@SUBSYSTEM=$* ./docker-compose-env.sh

%-up: ## up subsystem
	$(MAKE) -C $* up

%-down: ## down subsystem
	$(MAKE) -C $* down

%-clean: ## clean subsystem
	$(MAKE) -C $* clean
