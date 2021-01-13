#!/usr/bin/env bash

: '
    Copyright (C) 2021 IBM Corporation

    Elayaraja Dhanapal <eldhanap@in.ibm.com> - Initial implementation.
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

OCP_VERSION=ocp-$1

export DOCKER_CLI_EXPERIMENTAL=enabled

docker manifest create quay.io/powercloud/ocp4-powervs-automation-runtime:$OCP_VERSION \
quay.io/powercloud/ocp4-powervs-automation-runtime:ocp-$VERSION-x86_64 quay.io/powercloud/ocp4-powervs-automation-runtime:ocp-$VERSION-ppc64le

docker login quay.io -u $USER_QUAY -p $PWD_QUAY

docker manifest push quay.io/powercloud/ocp4-powervs-automation-runtime:$OCP_VERSION
