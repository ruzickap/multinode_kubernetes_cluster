#!/usr/bin/env bash

################################################
# include the demo-magic script
################################################
# demo-magic.sh is a handy shell script that enables you to script repeatable demos in a bash environment.
# It simulates typing of your commands, so you don't have to type them by yourself when you are presenting.
test -f ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
. ./demo-magic.sh -n

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=40

# Set positive values to run interactively
export PROMPT_TIMEOUT=0

# No wait after "p" or "pe"
export NO_WAIT=true

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

vagrant destroy -f
test -d kubespray && rm -rf kubespray
test -f kubeconfig.conf && rm kubeconfig.conf

# hide the evidence
clear

p  "### Kubernetes installation using kubespray"
wait

p  ""
p  "# Check the Vagrantfile and start 3 VMs"
pe "cat Vagrantfile"
pe 'VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up'

p  ""
p  "# Set IPs form VMs and store them into variables to store them in /etc/hosts later"
wait

p  ""
pe "NODE1_IP=`getent hosts node1 | cut -d' ' -f1`"
pe "NODE2_IP=`getent hosts node2 | cut -d' ' -f1`"
pe "NODE3_IP=`getent hosts node3 | cut -d' ' -f1`"

p  ""
p  "# Clone kubespray repo"
wait

p  ""
pe "git clone https://github.com/kubernetes-incubator/kubespray.git"
pe "cd kubespray"
pe "git checkout tags/v2.5.0"

p  ""
p  "# Prepare the config directory and change the config files"
wait

p  ""
pe "cp -rfp inventory/sample inventory/mycluster"
pe "IPS=\"$NODE1_IP $NODE2_IP $NODE3_IP\""
pe "CONFIG_FILE=inventory/mycluster/hosts.ini python3 contrib/inventory_builder/inventory.py \$IPS"
pe "mkdir ./inventory/mycluster/credentials"
pe 'echo "kube123" > ./inventory/mycluster/credentials/kube_user.creds'

p  "# Configure ./inventory/mycluster/group_vars/{all.yml,k8s-cluster.yml} variables"
pe "sed -i 's/^bootstrap_os:.*/bootstrap_os: ubuntu/' ./inventory/mycluster/group_vars/all.yml"
pe "sed -i 's@^# kubeconfig_localhost:.*@kubeconfig_localhost: true@' ./inventory/mycluster/group_vars/k8s-cluster.yml"

p  ""
p  "# Start the installation"
wait

pe "ansible-playbook --user vagrant --become -i inventory/mycluster/hosts.ini cluster.yml"
pe "cd .."

p  ""
p  "# Copy the kubeconfig to the local machine and get some basic details about kuberenetes cluster"
wait

pe "cp kubespray/inventory/mycluster/artifacts/admin.conf kubeconfig.conf"
pe "export KUBECONFIG=$PWD/kubeconfig.conf"
pe "kubectl get nodes"
pe "kubectl get all --all-namespaces"

cat > /tmp/dashboard-admin.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF

p  ""
p  "# *** Start with:"
p  "# export KUBECONFIG=\$PWD/kubeconfig.conf"
p  "# kubectl get nodes"
p  "# kubectl get pods --all-namespaces -o wide"
p  "# kubectl create -f /tmp/dashboard-admin.yaml"
p  "# https://node1:6443/ui"
