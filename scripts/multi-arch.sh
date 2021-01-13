#!/usr/bin/env bash

: '
    Copyright (C) 2021 IBM Corporation

    Elayaraja Dhanapal <eldhanap@in.ibm.com> - Initial implementation.
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

OCP_VERSION=ocp-$1

export DOCKER_CLI_EXPERIMENTAL=enabled

docker manifest create quay.io/powercloud/ocp-upi-powervs-pod:$OCP_VERSION \
quay.io/powercloud/ocp-upi-powervs-pod:ocp-$VERSION-x86_64 quay.io/powercloud/ocp-upi-powervs-pod:ocp-$VERSION-ppc64le

docker login quay.io -u $USER_QUAY -p $PWD_QUAY

docker manifest push quay.io/powercloud/ocp-upi-powervs-pod:$OCP_VERSION
