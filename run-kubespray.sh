#!/bin/bash -eu

VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up

test -d kubespray && rm -rf kubespray
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray
git checkout tags/v2.5.0

# Copy ``inventory/sample`` as ``inventory/mycluster``
cp -rfp inventory/sample inventory/mycluster

NODE1_IP=`getent hosts node1 | cut -d' ' -f1`
NODE2_IP=`getent hosts node2 | cut -d' ' -f1`
NODE3_IP=`getent hosts node3 | cut -d' ' -f1`

declare -a IPS=($NODE1_IP $NODE2_IP $NODE3_IP)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}

mkdir ./inventory/mycluster/credentials
echo "kube123" > ./inventory/mycluster/credentials/kube_user.creds

# ./inventory/mycluster/group_vars/all.yml
sed -i 's/^bootstrap_os:.*/bootstrap_os: ubuntu/' ./inventory/mycluster/group_vars/all.yml
sed -i 's/^#kubelet_load_modules:.*/kubelet_load_modules: true/' ./inventory/mycluster/group_vars/all.yml
sed -i 's/^#docker_storage_options:.*/docker_storage_options: -s overlay2/' ./inventory/mycluster/group_vars/all.yml

# ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^kube_api_anonymous_auth:.*@kube_api_anonymous_auth: false@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^kube_service_addresses:.*@kube_service_addresses: 192.168.119.0/24@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^k8s_image_pull_policy:.*@k8s_image_pull_policy: Always@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^# kubeconfig_localhost:.*@kubeconfig_localhost: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml

#Install Python (if needed) which is requirement for Ansible
ansible-playbook --user vagrant --become -i inventory/mycluster/hosts.ini cluster.yml
cd ..

cp kubespray/inventory/mycluster/artifacts/admin.conf kubeconfig.conf

export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes
kubectl get pods --all-namespaces=true
