# Copyright 2022 VMware. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

ENV := dev
CARVEL_BINARIES := ytt kbld imgpkg kapp
PACKAGE_VERSION := latest
OCI_IMAGE := ghcr.io/alexandreroman/yelb-app

all: deploy

check-carvel:
	$(foreach exec,$(CARVEL_BINARIES),\
		$(if $(shell which $(exec)),,$(error "'$(exec)' not found. Carvel toolset is required. See instructions at https://carvel.dev/#install")))

lock: check-carvel # Updates the image lock file.
	kbld -f bundle/config --imgpkg-lock-output bundle/.imgpkg/images.yml

deploy: check-carvel
	ytt -f bundle/config -f bundle/config-env/${ENV} | kbld -f- > _tmp.yml
	kapp deploy -a yelb-${ENV} -f _tmp.yml -c -y
	rm -f _tmp.yml

deploy-lb: check-carvel
	ytt -f bundle/config -f bundle/config-env/${ENV} -f bundle/config-ext/load-balancer.yml | kbld -f- > _tmp.yml
	kapp deploy -a yelb-${ENV} -f _tmp.yml -c -y
	rm -f _tmp.yml

deploy-ingress: check-carvel
	ytt -f bundle/config -f bundle/config-env/${ENV} -f bundle/config-ext/ingress.yml | kbld -f- > _tmp.yml
	kapp deploy -a yelb-${ENV} -f _tmp.yml -c -y
	rm -f _tmp.yml

deploy-ingress-tls: check-carvel
	ytt -f bundle/config -f bundle/config-env/${ENV} -f bundle/config-ext/ingress.yml -f bundle/config-ext/ingress-tls.yml | kbld -f- > _tmp.yml
	kapp deploy -a yelb-${ENV} -f _tmp.yml -c -y
	rm -f _tmp.yml

undeploy:
	kapp delete -a yelb-${ENV} -y

push: check-carvel # Build and push bundle.
	imgpkg push --bundle $(OCI_IMAGE):${PACKAGE_VERSION} --file bundle/
