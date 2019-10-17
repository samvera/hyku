SHELL = /bin/bash

export KUBE_IP := 134.209.48.118
export COMMON_NAME := hyku-puma.$(KUBE_IP).nip.io

ifeq ($(TAG),)
	tag := 0.0.1
else
	tag := $(TAG)
endif

ifeq ($(RELEASE),)
	release := staging
else
	release := $(RELEASE)
endif

all:
	$(MAKE) helm-init
	$(MAKE) kubectl-create-secret-tls
	$(MAKE) helm-upgrade
	$(MAKE) open

clean:
	rm -f server.pem server.key
	$(MAKE) helm-delete
	$(MAKE) helm-reset

update: 
	$(MAKE) TAG=$(tag) deploy

helm-init:
	helm init --wait

helm-reset:
	helm reset

helm-upgrade:
	helm upgrade $(release) . --install --wait --set ingress.host=$(COMMON_NAME)

helm-delete:
	helm delete $(release) --purge
#	kubectl delete secret hyku-puma-tls

helm-template:
	helm template . --name $(release)

hel-dependencies-build:
	helm dependency build

deploy:
	helm upgrade $(release) . --install --wait --set ingress.host=$(COMMON_NAME) --set rails.image.tag=$(TAG)

server.pem:
	openssl req -new -x509 -nodes -keyout server.key -days 3650 \
		-subj "/CN=${COMMON_NAME}" \
		-extensions v3_req \
		-config <(cat openssl.conf | sed s/\$${COMMON_NAME}/$(COMMON_NAME)/) > server.pem
	openssl x509 -text < server.pem

kubectl-create-secret-tls: server.pem
	kubectl delete secret hyku-puma-tls --ignore-not-found
	kubectl create secret tls hyku-puma-tls --key server.key --cert server.pem

open:
	open https://$(COMMON_NAME)

stern:
	stern $(release)-demoapp.*
