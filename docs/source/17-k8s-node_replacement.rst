Node replacement
================

Move all pods away from node2

.. code-block:: shell-session

   $ kubectl drain --ignore-daemonsets node2

Get pod details

.. code-block:: shell-session

   $ kubectl get pods -o wide

Destroy the node node2

.. code-block:: shell-session

   $ vagrant destroy -f node2

Wait some time for Kubernetes to catch up...

.. code-block:: shell-session

   $ sleep 30

The node2 shoult be in 'NotReady' state

.. code-block:: shell-session

   $ kubectl get nodes

Remove the node2 from the cluster

.. code-block:: shell-session

   $ kubectl delete node node2

Generate command which can add new node to Kubernetes cluster

.. code-block:: shell-session

   $ KUBERNETES_JOIN_CMD=$(ssh $SSH_ARGS root@node1 "kubeadm token create --print-join-command"); echo $KUBERNETES_JOIN_CMD

Start new node

.. code-block:: shell-session

   $ vagrant up node2

Install Kubernetes repository to new node

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node2 "sudo sh -xc \" DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https curl > /dev/null; curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -; echo deb https://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list \""

Install Kubernetes packages

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node2 "sudo sh -xc \" apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io kubelet=${KUBERNETES_UPGRADE_VERSION}-00 kubeadm=${KUBERNETES_UPGRADE_VERSION}-00 kubectl=${KUBERNETES_UPGRADE_VERSION}-00 > /dev/null \""

Join node2 to the Kuberenets cluster

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node2 "sudo sh -xc \" $KUBERNETES_JOIN_CMD \""
   $ sleep 30

Check the nodes - node2 should be there

.. code-block:: shell-session

   $ kubectl get nodes
