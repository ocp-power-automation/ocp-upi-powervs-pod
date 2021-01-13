# ocp4-powervs-automation-runtime
Deploy a new OpenShift Cluster on PowerVS from within another OpenShift, running the setup from a pod.

## Step 0: PowerVS Preparation Checklist

- [ ] **[Create a paid IBM Cloud Account](https://cloud.ibm.com/)**.
- [ ] **[Create an API key](https://cloud.ibm.com/docs/account?topic=account-userapikey)**.
- [ ] Add a new instance of an Object Storage Service (or reuse any existing one):
	- [ ] Create a new bucket.
	- [ ] Create a new credential with HMAC enabled.
	- [ ] Create and upload (or just upload if you already have it) the required .ova images.
- [ ] Add a new instance of the Power Virtual Service.
	- [ ] Create a private network and **[create a support ticket](https://cloud.ibm.com/unifiedsupport/cases/form)** to enable connectivity between the VMs within this private network. [Take a look at this video to learn how to create a new support ticket](https://youtu.be/S5ljNc2kU_A).
	- [ ] [Create the boot images](https://cloud.ibm.com/docs/power-iaas?topic=power-iaas-importing-boot-image).
	
**NOTE:** Details about the checklist steps can be found [here](https://github.com/ocp-power-automation/ocp4-upi-powervs/blob/master/docs/ocp_prereqs_powervs.md).

## Step 1: Get OpenShift Secret

1. **[Create an account at RedHat portal](https://www.redhat.com/wapps/ugc/register.html?_flowId=register-flow&_flowExecutionKey=e1s1)**
2. Go to **[bit.ly/ocp-secrets](bit.ly/ocp-secrets)** and copy the pull secret.
3. Paste the secret in the **[ocp-secrets](cluster-configuration/ocp-secrets)** file:

```
cluster-configuration/ocp-secrets
```

## Step 2: Configure the Variables

Set the required variables by setting its values in the following files

```
cluster-configuration/ocp-variables
```

**NOTE**: you can use the [PowerVS Actions](https://github.com/rpsene/powervs-actions) to get the necessary information to fill in the variables.

The variables you need to set are the following:

```
  IBMCLOUD_API_KEY=
  IBMCLOUD_REGION=
  IBMCLOUD_ZONE=
  POWERVS_INSTANCE_ID=
  BASTION_IMAGE_NAME=
  RHCOS_IMAGE_NAME=
  PROCESSOR_TYPE=
  SYSTEM_TYPE=
  PRIVATE_NETWORK_NAME=
  CLUSTER_DOMAIN=
  STORAGE_CLASS_NAME=
  PVC_SIZE=
```

In you need to set a proxy for the application running from within the pod, add the following variables (you can set the same value for both):

```
  HTTP_PROXY=
  HTTPS_PROXY=
```

You can get the proxy information set as part of your cluster using:

```
  oc get proxy/cluster -o template --template {{.spec.httpProxy}}
  oc get proxy/cluster -o template --template {{.spec.httpsProxy}}
```

**IMPORTANT:** if you are using a **RHEL** image for the bastion, you must add the following variables and its respectives values in the aforementioned variables file:

```
  RHEL_SUBS_USERNAME=
  RHEL_SUBS_PASSWORD=
```

**NOTE:** [Red Hat business partners who have signed a partner agreement are eligible to receive limited quantities of free Not for Resales (NFR) software subscriptions as benefits of participating in partner programs.](https://www.redhat.com/files/other/partners/Howtoguide-createanewNFR.pdf)

## Step 3: Create a new cluster

```
ACTION=apply; OCP_VERSION=4.6; NEW_CLUSTER=$(./deploy.sh $ACTION $OCP_VERSION); \
cd ./clusters/$NEW_CLUSTER; \
oc new-project $NEW_CLUSTER --description="OCP Cluster on PowerVS" \
--display-name="OCP on PowerVS - $NEW_CLUSTER"; \
oc create -f ./secret.yaml; \
oc create -f ./pvc.yaml; \
oc create -f ./ocp-cluster.yaml
```

## Step 4: Destroy a cluster

```
CLUSTER_ID=<SET ME>
ACTION=destroy; CLUSTER=$CLUSTER_ID; \
./deploy.sh $ACTION $CLUSTER; \
cd ./clusters/$CLUSTER_ID; \
oc delete -f ./ocp-cluster.yaml; \
oc create -f ./ocp-cluster.yaml; \
oc delete -f ./secret.yaml; \
oc delete -f ./pvc.yaml; \
oc delete project $CLUSTER_ID
```

Example: 

```
# tree -L 2
.
|-- ocp-46-20210112-104034-b16efae55f
    |-- ocp-cluster.yaml
    |-- pvc.yaml
    `-- secret.yaml
`-- ocp-46-20210112-104320-cebd1c0900
    |-- ocp-cluster.yaml
    |-- pvc.yaml
    `-- secret.yaml

CLUSTER_ID=ocp-46-20210112-104034-b16efae55f

ACTION=destroy; CLUSTER=$CLUSTER_ID; \
./deploy.sh $ACTION $CLUSTER; \
cd ./clusters/$CLUSTER_ID; \
oc delete -f ./ocp-cluster.yaml; \ 	# deletes the first deployment, which created the cluster.
oc create -f ./ocp-cluster.yaml; \ 	# deploys a new pod to delete the cluster.
oc delete -f ./secret.yaml; \		# deletes the secrets created
oc delete -f ./pvc.yaml; \ 		# deletes the PVC allocated (you can ignore this step)
oc delete project $CLUSTER_ID		# deletes the project create for deploying this cluster 
```
