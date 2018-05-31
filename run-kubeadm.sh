#!/bin/bash -eu

MYUSER="vagrant"
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
POD_NETWORK_CIDR="10.244.0.0/16"
KUBERNETES_VERSION="1.10.3"
CNI_URL="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

INSTALL_KUBERNETES="
export DEBIAN_FRONTEND='noninteractive'
apt-get update -qq && apt-get install -y -qq apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat > /etc/apt/sources.list.d/kubernetes.list << EOF2
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF2
apt-get update -qq
apt-get install -y -qq --no-install-recommends docker.io kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00
"


test -f $HOME/.ssh/id_rsa || ( install -m 0700 -d $HOME/.ssh && ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N "" )

echo "# Start 3 VMs"
VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up

echo "# Set IPs form VMs and store them into variables"
NODE1_IP=`getent hosts node1 | cut -d' ' -f1`
NODE2_IP=`getent hosts node2 | cut -d' ' -f1`
NODE3_IP=`getent hosts node3 | cut -d' ' -f1`

echo "# Fill the /etc/hosts on each cluster node"
for COUNTER in {1..3}; do
  ssh -t ${MYUSER}@node$COUNTER ${SSH_ARGS} "sudo /bin/bash -c '
    sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.d/99-sysctl.conf
    sysctl --quiet --system
    cat >> /etc/hosts << EOF2
$NODE1_IP node1 node1.cluster.local
$NODE2_IP node2 node2.cluster.local
$NODE3_IP node3 node3.cluster.local
EOF2'"
done

echo "# Install kubernetes Master"
ssh -t ${MYUSER}@node1 ${SSH_ARGS} "sudo /bin/bash -cx '
$INSTALL_KUBERNETES

kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version v${KUBERNETES_VERSION}

test -d /home/$MYUSER/.kube || mkdir /home/$MYUSER/.kube
cp -i /etc/kubernetes/admin.conf /home/$MYUSER/.kube/config
chown -R $MYUSER:$MYUSER /home/$MYUSER/.kube

export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl apply -f $CNI_URL
'"

echo "# Create bootstrap token command using: ssh ${MYUSER}@node1 \"sudo kubeadm token create --print-join-command\""
KUBEADM_TOKEN_COMMAND=`ssh -t ${MYUSER}@node1 ${SSH_ARGS} "sudo kubeadm token create --print-join-command"`

echo "# Install Kubernetes packages to all nodes and join the nodes to the master using bootstrap token"
for COUNTER in {2..3}; do
  echo "*** node$COUNTER"
  nohup ssh -t ${MYUSER}@node$COUNTER ${SSH_ARGS} "sudo /bin/bash -cx '
$INSTALL_KUBERNETES > /dev/null
hostname
$KUBEADM_TOKEN_COMMAND
'" &
done

echo "# Copy the kubeconfig to the local machine and get some basic details about kuberenetes cluster"
scp ${SSH_ARGS} ${MYUSER}@node1:~/.kube/config kubeconfig.conf

export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes

echo "*** Allow pods to be scheduled on the master"
kubectl taint nodes node1 node-role.kubernetes.io/master-

echo "*** Enable routing from local machine (host) to the kubernetes pods/services/etc"
echo "*** Adding routes (10.244.0.0/16, 10.96.0.0/12) -> [$NODE1_IP]"
sudo bash -c "ip route | grep -q 10.244.0.0/16 && ip route del 10.244.0.0/16; ip route add 10.244.0.0/16 via $NODE1_IP"
sudo bash -c "ip route | grep -q 10.96.0.0/12  && ip route del 10.96.0.0/12;  ip route add 10.96.0.0/12  via $NODE1_IP"

cat << \EOF
*** Wait few minutes for the worker nodes to join..."
*** Start with:
export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes
EOF
