FROM quay.io/powercloud/powervs-container-host:ocp-VERSION

RUN mkdir -p /ocp-automation/ && mkdir -p /var/app/

WORKDIR /ocp-automation

RUN git clone --single-branch --branch release-VERSION https://github.com/ocp-power-automation/ocp4-upi-powervs.git ./

RUN ["/bin/bash", "-c", "terraform init"]

COPY ./deploy-ocp-cluster.sh .

RUN chmod +x ./deploy-ocp-cluster.sh

ENTRYPOINT ["/bin/bash", "-c", "./deploy-ocp-cluster.sh"]