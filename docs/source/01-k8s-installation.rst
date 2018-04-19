Kubernetes Installation
=======================

It's expected, that you will install Kubernetes to 4 VMs / hosts - to have multinode installation.
The installation part is taken from these two URLs:

- https://kubernetes.io/docs/setup/independent/install-kubeadm/
- https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/


Master node installation
------------------------

SSH to the first VM which will be your Master node:

.. code-block:: shell-session

   $ ssh root@node1

Set the Kubernetes version which will be installed:

.. code-block:: shell-session

   $ KUBERNETES_VERSION="1.10.0"

Set the proper `CNI <https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/#cni>`_ URL:

.. code-block:: shell-session

   $ CNI_URL="https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml"

For Flannel installation you need to use proper "pod-network-cidr":

.. code-block:: shell-session

   $ POD_NETWORK_CIDR="10.244.0.0/16"

Add the Kubernetes repository (`details <https://kubernetes.io/docs/setup/independent/install-kubeadm/>`_):

.. code-block:: shell-session

   $ apt-get update -qq && apt-get install -y -qq apt-transport-https curl
   $ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   $ tee /etc/apt/sources.list.d/kubernetes.list << EOF2
   deb https://apt.kubernetes.io/ kubernetes-xenial main
   EOF2

Install necessary packages:

.. code-block:: shell-session

   $ apt-get update -qq
   $ apt-get install -y -qq docker.io kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00

Install Kubernetes Master:

.. code-block:: shell-session

   $ kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --kubernetes-version v${KUBERNETES_VERSION}

Copy the "kubectl" config files to the home directory:

.. code-block:: shell-session

   $ test -d $HOME/.kube || mkdir $HOME/.kube
   $ cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   $ chown -R $USER:$USER $HOME/.kube

Install CNI:

.. code-block:: shell-session

   $ export KUBECONFIG=/etc/kubernetes/admin.conf
   $ kubectl apply -f $CNI_URL

Your Kuberenets Master node should be ready now. You can check it using this command:

.. code-block:: shell-session

   $ kubectl get nodes


Worker nodes installation
-------------------------

Let's connect the worker nodes now

SSH to the worker nodes and repeat these commands on all of them in paralel:

.. code-block:: shell-session

   $ ssh root@node2
   $ ssh root@node3
   $ ssh root@node4

Set the Kubernetes version which will be installed:

.. code-block:: shell-session

   $ KUBERNETES_VERSION="1.10.0"

Add the Kubernetes repository (`details <https://kubernetes.io/docs/setup/independent/install-kubeadm/>`_):

.. code-block:: shell-session

   $ apt-get update -qq && apt-get install -y -qq apt-transport-https curl
   $ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   $ tee /etc/apt/sources.list.d/kubernetes.list << EOF2
   deb https://apt.kubernetes.io/ kubernetes-xenial main
   EOF2

Install necessary packages:

.. code-block:: shell-session

   $ apt-get update -qq
   $ apt-get install -y -qq docker.io kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00

All the woker nodes are prepared now - let's connect them to master node.
SSH to the master node again and generate the "joining" command:

.. code-block:: shell-session

   $ ssh -t root@node1 "kubeadm token create --print-join-command"

You sould see something like:

.. code-block:: shell-session

   $ kubeadm join <master-ip>:<master-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>

Execute the generated command on all worker nodes.

.. code-block:: shell-session

   $ ssh -t root@node2 "kubeadm join --token ..."
   $ ssh -t root@node3 "kubeadm join --token ..."
   $ ssh -t root@node4 "kubeadm join --token ..."

SSH back to the master nodes and check the cluster status - all the nodes should appear there in "Ready" status after while.

.. code-block:: shell-session

   $ ssh root@node1
   $ # Check nodes
   $ kubectl get nodes


Real installation example
-------------------------

.. raw:: html

   <script src="https://asciinema.org/a/176954.js" id="asciicast-176954" async></script>
