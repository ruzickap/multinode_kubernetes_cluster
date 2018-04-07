#!/bin/bash -eux

# http://rancher.com/announcing-rke-lightweight-kubernetes-installer/

VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up

test -d kubespray && rm -rf kubespray
git clone https://github.com/kubernetes-incubator/kubespray.git
cd kubespray

# Copy ``inventory/sample`` as ``inventory/mycluster``
cp -rfp inventory/sample inventory/mycluster

NODE1_IP=`getent hosts node1 | cut -d' ' -f1`
NODE2_IP=`getent hosts node2 | cut -d' ' -f1`
NODE3_IP=`getent hosts node3 | cut -d' ' -f1`
NODE4_IP=`getent hosts node4 | cut -d' ' -f1`

declare -a IPS=($NODE1_IP $NODE2_IP $NODE3_IP $NODE4_IP)
CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py ${IPS[@]}

mkdir ./inventory/mycluster/credentials
echo "kube123" > ./inventory/mycluster/credentials/kube_user.creds

sed -i 's/#docker_storage_options: -s overlay2/docker_storage_options: -s overlay2/' ./inventory/mycluster/group_vars/all.yml

sed -i 's@^kube_api_anonymous_auth: true@kube_api_anonymous_auth: false@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^# kubeconfig_localhost: false@kubeconfig_localhost: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml
#sed -i 's@^deploy_netchecker: false@deploy_netchecker: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^efk_enabled: false@efk_enabled: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^helm_enabled: false@helm_enabled: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^kube_service_addresses:.*@kube_service_addresses: 192.168.119.0/24@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^kube_network_plugin:.*@kube_network_plugin: flannel@' ./inventory/mycluster/group_vars/k8s-cluster.yml
sed -i 's@^ingress_nginx_enabled:.*@ingress_nginx_enabled: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml
cat >> ./inventory/mycluster/group_vars/k8s-cluster.yml << EOF
ingress_nginx_host_network: false
ingress_nginx_namespace: "ingress-nginx"
ingress_nginx_insecure_port: 80
ingress_nginx_secure_port: 443
ingress_nginx_configmap:
  map-hash-bucket-size: "128"
  ssl-protocols: "SSLv2"
# ingress_nginx_configmap_tcp_services:
#   9000: "default/example-go:8080"
# ingress_nginx_configmap_udp_services:
#   53: "kube-system/kube-dns:53"
EOF

#Install Python (if needed) which is requirement for Ansible
ansible --user vagrant -i inventory/mycluster/hosts.ini -m raw -a 'sudo bash -x -c "test -e /usr/bin/python || ( test -x /usr/bin/apt && ( apt -qqy update && apt install -y python-minimal ) || ( test -x /usr/bin/dnf && dnf install -y python ))"' all

ansible-playbook --user vagrant --become -i inventory/mycluster/hosts.ini cluster.yml

ssh vagrant@node1 << EOF
set -x
kubectl get nodes
kubectl get pods --all-namespaces=true
EOF
