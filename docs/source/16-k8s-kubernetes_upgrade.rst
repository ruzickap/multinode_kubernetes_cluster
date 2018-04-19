Kuberenetes upgrade
===================

Check the version of the nodes

.. code-block:: shell-session

   $ kubectl get nodes

Show versions of Kubernetes components

.. code-block:: shell-session

   $ kubectl get pods --namespace=kube-system -o=json | jq -r ".items[].spec.containers[] | .name + \" \" + .image" | column --table

Upgrade only the kubeadm first

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node1 "sudo sh -xc \" apt-get update -qq && cd /tmp && apt-get download kubeadm=${KUBERNETES_UPGRADE_VERSION}-00; dpkg --force-all -i kubeadm*amd64.deb \""

Perform the upgrade

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node1 "sudo kubeadm upgrade apply v${KUBERNETES_UPGRADE_VERSION} --yes"
   $ sleep 10

Upgrade CNI (flannel)

.. code-block:: shell-session

   $ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

Check the version on the nodes - master shloud be upgraded

.. code-block:: shell-session

   $ kubectl get nodes

Show versions of Kubernetes components

.. code-block:: shell-session

   $ kubectl get pods --namespace=kube-system -o=json | jq -r ".items[].spec.containers[] | .name + \" \" + .image" | column --table

Let's upgrade node1 form the OS level point of view.
Move all pods away from node1 (if you get the 'unable to drain' error - it is fine for master node)

.. code-block:: shell-session

   $ kubectl drain --ignore-daemonsets node1

All pods from node1 should be somewhere else

.. code-block:: shell-session

   $ kubectl get pods -o wide

Apply the upgrade plan

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node1 "sudo sh -xc \" apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq kubelet=${KUBERNETES_UPGRADE_VERSION}-00 kubeadm=${KUBERNETES_UPGRADE_VERSION}-00 kubectl=${KUBERNETES_UPGRADE_VERSION}-00 \""

Check the version on the nodes - see the SchedulingDisabled on node1

.. code-block:: shell-session

   $ kubectl get nodes

Enable node1 again

.. code-block:: shell-session

   $ kubectl uncordon node1
   $ sleep 10

node1 is ready again

.. code-block:: shell-session

   $ kubectl get nodes

See which pods are running on the node1

.. code-block:: shell-session

   $ kubectl get pods -o wide

Repeat the same steps for all nodes one by one

.. code-block:: shell-session

   $ set -x; for COUNT in {2..4}; do sleep 30; kubectl drain --ignore-daemonsets node${COUNT}; ssh $SSH_ARGS vagrant@node${COUNT} "sudo sh -xc \" apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get upgrade -qq -y kubelet=${KUBERNETES_UPGRADE_VERSION}-00 kubeadm=${KUBERNETES_UPGRADE_VERSION}-00 kubectl=${KUBERNETES_UPGRADE_VERSION}-00 \""; kubectl uncordon node${COUNT}; kubectl get nodes; kubectl get pods -o wide; done; set +x
   $ sleep 10

Check all the nodes

.. code-block:: shell-session

   $ kubectl get nodes
