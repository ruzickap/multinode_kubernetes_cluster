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

# hide the evidence
clear

p  "### Kubernetes installation using kubeadm"
wait

p  ""
p  "# Setup the initial variables"
pe 'export MYUSER="vagrant"'
pe 'SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"'
pe 'POD_NETWORK_CIDR="10.244.0.0/16"'
pe 'KUBERNETES_VERSION="1.10.0"'
pe 'CNI_URL="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"'

p  ""
p  "# Check the Vagrantfile and start 3 VMs"
pe "cat Vagrantfile"
pe 'VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up'

p  ""
p  "# Set IPs form VMs and store them into variables"
wait

p  ""
pe "NODE1_IP=`getent hosts node1 | cut -d' ' -f1`"
pe "NODE2_IP=`getent hosts node2 | cut -d' ' -f1`"
pe "NODE3_IP=`getent hosts node3 | cut -d' ' -f1`"

p  ""
p  "# Fill the /etc/hosts on each cluster node"
wait

pe "
for COUNTER in {1..3}; do
  ssh -t ${MYUSER}@node\$COUNTER ${SSH_ARGS} \"sudo /bin/bash -c '
  cat >> /etc/hosts << EOF2
$NODE1_IP node1 node1.cluster.local
$NODE2_IP node2 node2.cluster.local
$NODE3_IP node3 node3.cluster.local
EOF2'
\"
done"

INSTALL_KUBERNETES="
export DEBIAN_FRONTEND='noninteractive'
apt-get update -qq && apt-get install -y -qq apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat > /etc/apt/sources.list.d/kubernetes.list << EOF2
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF2
apt-get update -qq
apt-get install -y -qq docker.io kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00
"

p  ""
p  "# Install kubernetes Master"
pe "
ssh -t ${MYUSER}@node1 ${SSH_ARGS} \"sudo /bin/bash -cx '
$INSTALL_KUBERNETES
kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version v${KUBERNETES_VERSION}

test -d /home/$MYUSER/.kube || mkdir /home/$MYUSER/.kube
cp -i /etc/kubernetes/admin.conf /home/$MYUSER/.kube/config
chown -R $MYUSER:$MYUSER /home/$MYUSER/.kube

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl apply -f $CNI_URL
'\""

p  ""
p  "# Create bootstrap token command using: ssh ${MYUSER}@node1 \"sudo kubeadm token create --print-join-command\""
wait
pe "KUBEADM_TOKEN_COMMAND=\"$(ssh ${MYUSER}@node1 $SSH_ARGS 'sudo kubeadm token create --print-join-command')\""

p  ""
p  "# Install Kubernetes packages to all nodes and join the nodes to the master using bootstrap token"
wait
pe "
for COUNTER in {2..3}; do
  echo '*** node\$COUNTER'
  nohup ssh -t ${MYUSER}@node\$COUNTER $SSH_ARGS \"sudo /bin/bash -cx '
$INSTALL_KUBERNETES
$KUBEADM_TOKEN_COMMAND
'\" &
done"

p  ""
p  "# Copy the kubeconfig to the local machine and get some basic details about kuberenetes cluster"
wait
pe "scp ${MYUSER}@node1:~/.kube/config kubeconfig.conf"
pe "export KUBECONFIG=$PWD/kubeconfig.conf"
pe "kubectl get nodes"
pe "kubectl describe node node1"
pe "kubectl get all --all-namespaces"

p  ""
p  "# *** Wait few minutes for the worker nodes to join..."
p  "# *** Start with:"
p  "# export KUBECONFIG=\$PWD/kubeconfig.conf"
p  "# kubectl get nodes"
