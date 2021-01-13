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

    DEPENDENCIES=(oc curl)
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v $i &> /dev/null; then
            echo "ERROR: $i could not be found."
            exit 1
        fi
    done
}

function check_connectivity() {
    
    curl --output /dev/null --silent --head --fail http://cloud.ibm.com
    if [ ! $? -eq 0 ]; then
        echo
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function set_cluster_id() {

    CLUSTER=$1
    FILE=$2

    # sets the cluster ID for a given deployment
    sed -i -e "s/CLUSTERID/$CLUSTER/g" $FILE

}

function set_ocp_secrets() {

    CLUSTER=$1

    # check if the OCP secret is set and replace its value in 
    # the respective yaml file
    if [ -s "$(pwd)"/cluster-configuration/ocp-secrets ]; then
        SECRET=$(cat "$(pwd)"/cluster-configuration/ocp-secrets)

        # copies the base cluster secrets file to the directory of a new deployment
        cp -rp "$(pwd)"/yamls/secret.yaml "$(pwd)"/clusters/$CLUSTER

        # the cluster secrets file for the new cluster
        CLUSTER_SECRETS="$(pwd)"/clusters/$CLUSTER/secret.yaml

        # sets the ocp secret for a given deployment
        sed -i -e "s/ocp-secret/$SECRET/g" "$CLUSTER_SECRETS"

        # sets the exclusive cluster id for the secrets of a given deployment
        set_cluster_id "$CLUSTER" "$CLUSTER_SECRETS"
	else
		echo
		echo "ERROR: ensure you have added the OpenShift Secrets at /cluster-configuration/ocp-secrets"	
		echo "       you can get it from bit.ly/ocp-secrets"
		echo
		exit 1
	fi
}

function set_volume_claim() {

    CLUSTER=$1

    # copies the base cluster pvc file to the directory of a new deployment
    cp -rp "$(pwd)"/yamls/pvc.yaml "$(pwd)"/clusters/$CLUSTER

    # the new cluster's pvc file
    CLUSTER_PVC="$(pwd)"/clusters/$CLUSTER/pvc.yaml

    # sets the exclusive cluster id for the secrets of a given deployment
    set_cluster_id "$CLUSTER" "$CLUSTER_PVC"
}

function set_cluster_config() {

    CLUSTER=$1

    # copies the base cluster config file to the directory of a new deployment
    cp -rp "$(pwd)"/yamls/ocp-cluster.yaml "$(pwd)"/clusters/$CLUSTER

    # the new cluster's pvc file
    CLUSTER_CONFIG="$(pwd)"/clusters/$CLUSTER/ocp-cluster.yaml

    # sets the exclusive cluster id for the secrets of a given deployment
    set_cluster_id "$CLUSTER" "$CLUSTER_CONFIG"
}

function set_variables() {

    local PREFIX=$1
    local SUFIX=$2
    local OCP_VERSION=$3
    local ACTION=$4
    local CLUSTER=$PREFIX"-"$SUFIX

    local CLUSTER_SECRETS="$(pwd)"/clusters/$CLUSTER/secret.yaml
    local CLUSTER_PVC="$(pwd)"/clusters/$CLUSTER/pvc.yaml
    local CLUSTER_CONFIG="$(pwd)"/clusters/$CLUSTER/ocp-cluster.yaml
    
    ### set variables related to the secrets
    # sets the API Key for a given cluster deployment, converting it to base64
    local IBMCLOUD_API_KEY=$(grep "IBMCLOUD_API_KEY" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    local IBMCLOUD_API_KEY_B64=$(echo -n $IBMCLOUD_API_KEY | base64)
    sed -i -e "s/ibm-cloud-api-key/$IBMCLOUD_API_KEY_B64/g" "$CLUSTER_SECRETS"

    # sets the RHEL subscription username for a given cluster deployment, converting it to base64
    local RHEL_SUBS_USERNAME=$(grep "RHEL_SUBS_USERNAME" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    local RHEL_SUBS_USERNAME64=$(echo -n $RHEL_SUBS_USERNAME | base64)
    sed -i -e "s/redhat-subscription-username/$RHEL_SUBS_USERNAME64/g" "$CLUSTER_SECRETS"

    # sets the RHEL subscription password for a given cluster deployment, converting it to base64
    local RHEL_SUBS_PASSWORD=$(grep "RHEL_SUBS_PASSWORD" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    local RHEL_SUBS_PASSWORD64=$(echo -n $RHEL_SUBS_PASSWORD | base64)
    sed -i -e "s/redhat-subscription-password/$RHEL_SUBS_PASSWORD64/g" "$CLUSTER_SECRETS"
    ### end secrets variables

    ### set variables related to the pvc
    local STORAGE_CLASS_NAME=$(grep "STORAGE_CLASS_NAME" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/STORAGE_CLASS_NAME/$STORAGE_CLASS_NAME/g" "$CLUSTER_PVC"

    local PVC_SIZE=$(grep "PVC_SIZE" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/PVC_SIZE/$PVC_SIZE/g" "$CLUSTER_PVC"
    ### end pvc variables

    ### set cluster deployment variables
    local IBMCLOUD_REGION=$(grep "IBMCLOUD_REGION" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/ibmcloud_region/$IBMCLOUD_REGION/g" "$CLUSTER_CONFIG"

    local IBMCLOUD_ZONE=$(grep "IBMCLOUD_ZONE" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/ibmcloud_zone/$IBMCLOUD_ZONE/g" "$CLUSTER_CONFIG"

    local POWERVS_INSTANCE_ID=$(grep "POWERVS_INSTANCE_ID" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/powervs_instance_id/$POWERVS_INSTANCE_ID/g" "$CLUSTER_CONFIG"

    local PRIVATE_NETWORK_NAME=$(grep "PRIVATE_NETWORK_NAME" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/private_network_name/$PRIVATE_NETWORK_NAME/g" "$CLUSTER_CONFIG"

    local BASTION_IMAGE_NAME=$(grep "BASTION_IMAGE_NAME" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/bastion_image_name/$BASTION_IMAGE_NAME/g" "$CLUSTER_CONFIG"

    local RHCOS_IMAGE_NAME=$(grep "RHCOS_IMAGE_NAME" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/rhcos_image_name/$RHCOS_IMAGE_NAME/g" "$CLUSTER_CONFIG"

    local PROCESSOR_TYPE=$(grep "PROCESSOR_TYPE" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/processor_type/$PROCESSOR_TYPE/g" "$CLUSTER_CONFIG"

    local SYSTEM_TYPE=$(grep "SYSTEM_TYPE" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/system_type/$SYSTEM_TYPE/g" "$CLUSTER_CONFIG"

    local CLUSTER_DOMAIN=$(grep "CLUSTER_DOMAIN" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s/cluster_domain/$CLUSTER_DOMAIN/g" "$CLUSTER_CONFIG"

    sed -i -e "s/sufix/$SUFIX/g" "$CLUSTER_CONFIG"

    sed -i -e "s/prefix/$PREFIX/g" "$CLUSTER_CONFIG"

    sed -i -e "s/VERSION/$OCP_VERSION/g" "$CLUSTER_CONFIG"

    sed -i -e "s/action/$ACTION/g" "$CLUSTER_CONFIG"

    local HTTP_PROXY=$(grep "HTTP_PROXY" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s|http_proxy|$HTTP_PROXY|g" "$CLUSTER_CONFIG"

    local HTTPS_PROXY=$(grep "HTTPS_PROXY" "$(pwd)"/cluster-configuration/ocp-variables | tr -d " " | awk -F "=" '{print $2}')
    sed -i -e "s|https_proxy|$HTTPS_PROXY|g" "$CLUSTER_CONFIG"
    ### end cluster deployment variables
}

function check_variables() {

	INPUT="$(pwd)"/cluster-configuration/ocp-variables

	while IFS= read -r line; do
		VAR=$(echo "$line" | awk '{split($0,var,"="); print var[1]}')
		VALUE=$(echo "$line" | awk '{split($0,var,"="); print var[2]}')

		if [ -z $VALUE ]; then
	  		echo
	   		echo "ERROR: $VAR is not set."
	   		echo "      check the $INPUT file and try again."
	   		echo
	   		exit 1
		fi
	done < "$INPUT"
}

function create_project() {

    echo "creating deployment secrets..."
    #oc new-project $1
}

function create_secrets() {

    echo "creating deployment secrets..."
    #oc create -f $1/secret.yaml
}

function create_pvc_claim() {

    echo "creating pvc claim...."
    #oc create -f $1/pvc.yaml
}

function act() {

    echo "deploying new cluster..."
    #oc create -f $1/ocp-cluster.yaml
}

function run (){

    #check_dependencies
	check_connectivity

	local OCP_VERSIONS=("4.5" "4.6")
    local ACTIONS=("apply" "destroy")
    local ACTION=$1

	if [ -z $ACTION ]; then
        echo
        echo "ERROR: please, select one of the supported actions ${ACTIONS[@]}."
        echo "       e.g: ./deploy apply"
        echo
		exit 1
    elif [[ ! " ${ACTIONS[@]} " =~ " ${ACTION} " ]]; then
        echo
        echo "ERROR: this action is not supported."
        echo "       pick one of the following ${ACTIONS[@]}."
        echo
        exit 1
    fi
    if [[ "$ACTION" == "apply" ]]; then
        local OCP_VERSION=$2
        if [ -z $OCP_VERSION ]; then
		    echo
		    echo "ERROR: please, select one of the supported versions: ${OCP_VERSIONS[@]}."
		    echo "       e.g: ./deploy apply 4.6"
		    echo
		    exit 1
	    elif [[ ! " ${OCP_VERSIONS[@]} " =~ " ${OCP_VERSION} " ]]; then
		    echo
		    echo "ERROR: this version of OpenShift ($OCP_VERSION) is not supported."
		    echo "       pick one of the following: ${OCP_VERSIONS[@]}."
		    echo
		    exit 1
        else
            local TODAY=$(date "+%Y%m%d-%H%M%S")
            local SUFIX=$(openssl rand -hex 5)
            local PREFIX=$(echo "ocp-"$OCP_VERSION"-"$TODAY | tr -d .)
            local CLUSTERID=$PREFIX"-"$SUFIX
            local CLUSTER_CONFIG_LOCATION="$(pwd)"/clusters/$CLUSTERID

            check_variables
            mkdir -p "$(pwd)"/clusters/$CLUSTERID

            # prepar cluster configurations
            set_ocp_secrets "$CLUSTERID"
            set_volume_claim "$CLUSTERID"
            set_cluster_config "$CLUSTERID"
            set_variables "$PREFIX" "$SUFIX" "$OCP_VERSION" "$ACTION"

            #TODO automate the apply
            # deploy cluster
            # create_project "$CLUSTERID"
            # create_secrets "$CLUSTER_CONFIG_LOCATION"
            # create_pvc_claim "$CLUSTER_CONFIG_LOCATION"
            # act "$CLUSTER_CONFIG_LOCATION"

            echo $CLUSTERID
        fi
	elif [[ "$ACTION" == "destroy" ]]; then
        local CLUSTERS_LOCATION="$(pwd)"/clusters/
        local CLUSTERS=( $( ls $CLUSTERS_LOCATION ) )
        local CLUSTER=$2
        if [ -z $CLUSTER ]; then
		    echo
		    echo "ERROR: please, set the cluster you want to destroy."
		    echo "       e.g: ./deploy destroy ocp-46-20210108-185057-4eb0cfab8a"
		    echo
		    exit 1
	    elif [[ ! " ${CLUSTERS[@]} " =~ " ${CLUSTER} " ]]; then
		    echo
		    echo "ERROR: looks like this cluster ($1) was not deployed."
		    echo "       pick one of the following: ${CLUSTERS[@]}."
		    echo
		    exit 1
        else
            local CLUSTER_CONFIG_LOCATION="$(pwd)"/clusters/$CLUSTER
            local CLUSTER_CONFIG=$CLUSTER_CONFIG_LOCATION/ocp-cluster.yaml

            sed -i -e "s/value: \"apply\"/value: \"destroy\"/g" "$CLUSTER_CONFIG"

            #TODO automate the destroy
            # act "$CLUSTER_CONFIG_LOCATION"
        fi
    fi
}

run "$@"