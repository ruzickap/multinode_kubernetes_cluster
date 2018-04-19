Helm Installation
=================

Helm installation: https://github.com/kubernetes/helm/blob/master/docs/rbac.md

.. code-block:: shell-session

   $ curl -s $(curl -s https://github.com/kubernetes/helm | awk -F \" "/linux-amd64/ { print \$2 }") | tar xvzf - -C /tmp/ linux-amd64/helm
   $ sudo mv /tmp/linux-amd64/helm /usr/local/bin/
   # (Bug: https://github.com/kubernetes/helm/issues/2657)
   $ kubectl create serviceaccount tiller --namespace kube-system
   $ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
   $ helm init --service-account tiller
   $ sleep 30
   $ helm repo update

Install `Heapster <https://github.com/kubernetes/heapster>`_ - Compute Resource Usage Analysis and Monitoring of Container Clusters

.. code-block:: shell-session

   $ helm install --name my-heapster stable/heapster --set rbac.create=true
