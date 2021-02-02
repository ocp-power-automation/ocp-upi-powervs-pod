#!/usr/bin/env bash

: '
    Copyright (C) 2021 IBM Corporation

    Elayaraja Dhanapal <eldhanap@in.ibm.com> - Initial implementation.
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "bye!"
    exit 1
}

function check_dependencies() {

	local DEPENDENCIES=(terraform jq)
	for dep in "${DEPENDENCIES[@]}"
	do
		if ! command -v $dep &> /dev/null; then
				echo "ERROR: $dep could not be found."
				exit 1
		fi
	done
}

function terraform_apply() {

    local SUFIX=$CLUSTER_ID
    local PREFIX=$CLUSTER_ID_PREFIX

    local CLUSTER_DIR="/var/app/$PREFIX-$SUFIX"
    mkdir -p "$CLUSTER_DIR"

    ssh-keygen -t rsa -b 4096 -N '' -f ./data/id_rsa
    echo $PULL_SECRET >> ./data/pull-secret.txt

    time terraform apply -auto-approve -var-file var.tfvars \
    -var ibmcloud_api_key="$IBMCLOUD_API_KEY" \
    -var ibmcloud_region="$IBMCLOUD_REGION" \
    -var ibmcloud_zone="$IBMCLOUD_ZONE" \
    -var service_instance_id="$POWERVS_INSTANCE_ID" \
    -var rhel_image_name="$BASTION_IMAGE_NAME" \
    -var rhcos_image_name="$RHCOS_IMAGE_NAME" \
    -var processor_type="$PROCESSOR_TYPE" \
    -var system_type="$SYSTEM_TYPE" \
    -var network_name="$PRIVATE_NETWORK_NAME" \
    -var rhel_subscription_username="$RHEL_SUBS_USERNAME" \
    -var rhel_subscription_password="$RHEL_SUBS_PASSWORD" \
    -var cluster_id="$CLUSTER_ID" \
    -var cluster_id_prefix="$CLUSTER_ID_PREFIX" \
    -var openshift_install_tarball="$OPENSHIFT_INSTALL_TARBALL" \
    -var openshift_client_tarball="$OPENSHIFT_CLIENT_TARBALL" \
    -var cluster_domain="$CLUSTER_DOMAIN" | tee create.log

    local BASTION_IP=$(terraform output --json | jq -r '.bastion_public_ip.value')
    local BASTION_SSH=$(terraform output --json | jq -r '.bastion_ssh_command.value')
    local BASTION_HOSTNAME=$($BASTION_SSH -oStrictHostKeyChecking=no 'hostname')
    local CLUSTER_ID=$(terraform output --json | jq -r '.cluster_id.value')
    local KUBEADMIN_PWD=$($BASTION_SSH -oStrictHostKeyChecking=no 'cat ~/openstack-upi/auth/kubeadmin-password; echo')
    local WEBCONSOLE_URL=$(terraform output --json | jq -r '.web_console_url.value')
    local OCP_SERVER_URL=$(terraform output --json | jq -r '.oc_server_url.value')

cat << EOF
****************************************************************
  CLUSTER ACCESS INFORMATION
  Cluster ID: $CLUSTER_ID
  Bastion IP: $BASTION_IP ($BASTION_HOSTNAME)
  Bastion SSH: $BASTION_SSH
  OpenShift Access (user/pwd): kubeadmin/$KUBEADMIN_PWD
  Web Console: $WEBCONSOLE_URL
  OpenShift Server URL: $OCP_SERVER_URL
****************************************************************
EOF

    cp -r ./* "$CLUSTER_DIR"
    echo "DONE"
}

function terraform_destroy() {

    local SUFIX=$CLUSTER_ID
    local PREFIX=$CLUSTER_ID_PREFIX
    local CLUSTER_DIR="/var/app/$PREFIX-$SUFIX"
    
    if [ -d "$CLUSTER_DIR" ]; then

        cp -r $CLUSTER_DIR/* ./

        time terraform destroy -auto-approve -var-file var.tfvars \
        -var ibmcloud_api_key="$IBMCLOUD_API_KEY" \
        -var ibmcloud_region="$IBMCLOUD_REGION" \
        -var ibmcloud_zone="$IBMCLOUD_ZONE" \
        -var service_instance_id="$POWERVS_INSTANCE_ID" \
        -var rhel_image_name="$BASTION_IMAGE_NAME" \
        -var rhcos_image_name="$RHCOS_IMAGE_NAME" \
        -var processor_type="$PROCESSOR_TYPE" \
        -var system_type="$SYSTEM_TYPE" \
        -var network_name="$PRIVATE_NETWORK_NAME" \
        -var rhel_subscription_username="$RHEL_SUBS_USERNAME" \
        -var rhel_subscription_password="$RHEL_SUBS_PASSWORD" \
        -var cluster_id="$CLUSTER_ID" \
        -var cluster_id_prefix="$CLUSTER_ID_PREFIX" \
        -var openshift_install_tarball="$OPENSHIFT_INSTALL_TARBALL" \
        -var openshift_client_tarball="$OPENSHIFT_CLIENT_TARBALL" \
        -var cluster_domain="$CLUSTER_DOMAIN" | tee destroy.log

        cp -r ./* "$CLUSTER_DIR"
	    echo "DONE"
    fi
}

function run (){

    check_dependencies
    local ACTIONS=("apply" "destroy")

    if [[ ! " ${ACTIONS[@]} " =~ " ${ACTION} " ]]; then
        echo
	    echo "ERROR: this action ($ACTION) is not supported."
        echo "       use one of the following: ${ACTIONS[@]}."
        echo
        exit 1
    fi
    if [[ "$ACTION" == "apply" ]]; then
        terraform_apply
    elif [[ "$ACTION" == "destroy" ]]; then
        terraform_destroy
    fi
}

run "$@"
