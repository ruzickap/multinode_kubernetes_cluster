#!/bin/bash -eux

MYUSER="vagrant"
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
POD_NETWORK_CIDR="10.244.0.0/16"
#KUBERNETES_VERSION="1.10.0"
KUBERNETES_VERSION="1.9.0"
#CNI_URL="https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml"
CNI_URL="https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml"

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


test -f $HOME/.ssh/id_rsa || ( install -m 0700 -d $HOME/.ssh && ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N "" )

VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up

NODE1_IP=`getent hosts node1 | cut -d' ' -f1`
NODE2_IP=`getent hosts node2 | cut -d' ' -f1`
NODE3_IP=`getent hosts node3 | cut -d' ' -f1`
NODE4_IP=`getent hosts node4 | cut -d' ' -f1`

for COUNTER in {1..4}; do
  ssh -t ${MYUSER}@node$COUNTER $SSH_ARGS "sudo /bin/bash -c '
    cat >> /etc/hosts << EOF2
$NODE1_IP node1 node1.cluster.local
$NODE2_IP node2 node2.cluster.local
$NODE3_IP node3 node3.cluster.local
$NODE4_IP node4 node4.cluster.local
EOF2'"
done

# Master configuration
ssh -t ${MYUSER}@node1 $SSH_ARGS "sudo /bin/bash -c '
$INSTALL_KUBERNETES

kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version v${KUBERNETES_VERSION}

test -d /home/$MYUSER/.kube || mkdir /home/$MYUSER/.kube
cp -i /etc/kubernetes/admin.conf /home/$MYUSER/.kube/config
chown -R $MYUSER:$MYUSER /home/$MYUSER/.kube

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f $CNI_URL
'"

KUBEADM_TOKEN_COMMAND=`ssh -t ${MYUSER}@node1 $SSH_ARGS "sudo kubeadm token create --print-join-command"`

for COUNTER in {2..4}; do
  echo "*** node$COUNTER"
  nohup ssh -t ${MYUSER}@node$COUNTER $SSH_ARGS "sudo /bin/bash -c '
$INSTALL_KUBERNETES
$KUBEADM_TOKEN_COMMAND
'" &
done

scp ${MYUSER}@node1:~/.kube/config kubeconfig.conf

export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes
kubectl get pods --all-namespaces=true
