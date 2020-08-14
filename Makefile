# TAG=$(shell date +%Y%m%d)
TAG=latest
DOCKER_HUB_ORG ?= jozian
DOCKER_HUB_PRJ ?= rapidpro
DOCKER_HUB_COURIER ?= courier
DOCKER_HUB_MAILROOM ?= mailroom
DOCKER_HUB_RP-ARCHIVER ?= rp-archiver
DOCKER_HUB_RP-INDEXER ?= rp-indexer
DOCKER_HUB_RP-DISCORD-PROXY ?= rp-discord-proxy
NETWORK_NAME = rapidpro
NETWORK_ID = $(shell docker network ls -qf name=${NETWORK_NAME})

network:
	@if [ -n "${NETWORK_ID}" ]; then \
		echo "The ${NETWORK_NAME} network already exists. Skipping..."; \
	else \
		docker network create ${NETWORK_NAME}; \
	fi

build:
	@docker-compose build --pull ${BUILD_ARGS}
	# @docker build --tag ${DOCKER_HUB_ORG}/${DOCKER_HUB_PRJ}:${TAG} .

build-no-cache:
	@docker-compose build --pull --no-cache ${BUILD_ARGS}

build-courier:
	@docker build --tag ${DOCKER_HUB_ORG}/${DOCKER_HUB_COURIER}:${TAG} -f ../courier/Dockerfile ../courier

build-mailroom:
	@docker build --tag ${DOCKER_HUB_ORG}/${DOCKER_HUB_MAILROOM}:${TAG} -f ../mailroom/Dockerfile ../mailroom

build-rp-archiver:
	@docker build --tag ${DOCKER_HUB_ORG}/${DOCKER_HUB_RP-ARCHIVER}:${TAG} -f ../rp-archiver/Dockerfile ../rp-archiver

build-rp-indexer:
	@docker build --tag ${DOCKER_HUB_ORG}/${DOCKER_HUB_RP-INDEXER}:${TAG} -f ../rp-indexer/Dockerfile ../rp-indexer

build-rp-discord-proxy:
	@docker build --tag ${DOCKER_HUB_ORG}/${DOCKER_HUB_RP-DISCORD-PROXY}:${TAG} -f ../rp-discord-proxy/Dockerfile ../rp-discord-proxy

push:
	docker push ${DOCKER_HUB_ORG}/${DOCKER_HUB_PRJ}:${TAG}

up: network
	@sudo sysctl -w vm.max_map_count=262144
	@echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
	@docker-compose up
	# @docker-compose up ${DOCKER_HUB_PRJ}

down:
	@docker-compose down

up-prod: network
	@sudo sysctl -w vm.max_map_count=262144
	@echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
	@docker-compose -f ./docker-compose.yml -f ./docker-compose.prod.yml up

down-prod:
	@docker-compose -f ./docker-compose.yml -f ./docker-compose.prod.yml down --remove-orphans

shell:
	@docker-compose exec ${DOCKER_HUB_PRJ} bash

db-migrate:
	@docker-compose exec ${DOCKER_HUB_PRJ} python manage.py migrate

reset:
	# @sudo rm -rf ../rapidpro-data/

	@mkdir ../primero-data/
	@mkdir -p ../rapidpro-data/rapidpro/sitestatic/
	@cp temba/settings.py.dev.docker ../rapidpro-data/rapidpro/


	@mkdir -p ../primero-data/db/data/

	@mkdir ../primero-data/letsencrypt/

	@mkdir -p ../rapidpro-data/es/data/

	@mkdir -p ../rapidpro-data/celery/schedule

	@mkdir -p ../rapidpro-data/rp-discord-proxy
	@cp ../rp-discord-proxy/config.toml.example ../rapidpro-data/rp-discord-proxy/config.toml

clone:
	@git clone --branch docker git@github.com:Jozian/courier.git ../courier
	@git clone --branch docker git@github.com:Jozian/mailroom.git ../mailroom
	@git clone --branch docker git@github.com:Jozian/rp-archiver.git ../rp-archiver
	@git clone --branch docker git@github.com:Jozian/rp-indexer.git ../rp-indexer
	@git clone git@github.com:awensaunders/RapidPro-Discord-Proxy.git ../rp-discord-proxy

docker-setup:
	@sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
	@curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	@sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(shell lsb_release -cs) stable"
	@sudo apt-get install python-is-python3 python3-distutils
	@sudo apt-get install docker-ce docker-ce-cli containerd.io
	@curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
	@sudo python ./get-pip.py
	@sudo pip install docker-compose
