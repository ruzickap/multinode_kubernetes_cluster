#!/bin/bash -eux

USER="vagrant"
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
POD_NETWORK_CIDR="10.244.0.0/16"
CNI_URL="https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml"

test -f $HOME/.ssh/id_rsa || ( install -m 0700 -d $HOME/.ssh && ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N "" )

VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up

NODE1_IP=`getent hosts node1 | cut -d' ' -f1`
NODE2_IP=`getent hosts node2 | cut -d' ' -f1`
NODE3_IP=`getent hosts node3 | cut -d' ' -f1`
NODE4_IP=`getent hosts node4 | cut -d' ' -f1`

for COUNTER in {1..4}; do
  ssh root@node$COUNTER $SSH_ARGS << EOF
    cat >> /etc/hosts << EOF2
$NODE1_IP node1 node1.cluster.local
$NODE2_IP node2 node2.cluster.local
$NODE3_IP node3 node3.cluster.local
$NODE4_IP node4 node4.cluster.local
EOF2
EOF
done

# Master configuration
ssh root@node1 $SSH_ARGS << EOF
export DEBIAN_FRONTEND="noninteractive"
apt-get update -qq && apt-get install -y -qq apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat > /etc/apt/sources.list.d/kubernetes.list << EOF2
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF2
apt-get update -qq
apt-get install -y -qq docker.io kubelet kubeadm kubectl

kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR

test -d /home/$USER/.kube || mkdir /home/$USER/.kube
cp -i /etc/kubernetes/admin.conf /home/$USER/.kube/config
chown -R $USER:$USER /home/$USER/.kube

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f $CNI_URL
EOF

KUBEADM_TOKEN_COMMAND=`ssh root@node1 $SSH_ARGS "kubeadm token create --print-join-command"`

for COUNTER in {2..4}; do
  echo "*** node$COUNTER"
  ssh root@node$COUNTER $SSH_ARGS << EOF
export DEBIAN_FRONTEND="noninteractive"
apt-get update -qq && apt-get install -y -qq apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat > /etc/apt/sources.list.d/kubernetes.list << EOF2
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF2
apt-get update -qq
apt-get install -y -qq docker.io kubelet kubeadm kubectl

$KUBEADM_TOKEN_COMMAND
EOF
done

scp vagrant@node1:~/.kube/config kubeconfig.conf

export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes
kubectl get pods --all-namespaces=true
