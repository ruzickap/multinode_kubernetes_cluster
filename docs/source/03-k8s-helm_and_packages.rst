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

Install `nginx-ingress <https://github.com/kubernetes/ingress-nginx>`_ - NGINX Ingress Controller

.. code-block:: shell-session

   $ helm install stable/nginx-ingress --wait --name my-nginx --set controller.daemonset.useHostPort=true,controller.kind=DaemonSet,controller.metrics.enabled=true,controller.service.type=NodePort,controller.stats.enabled=true,rbac.create=true
   $ kubectl get pods --all-namespaces -l app=nginx-ingress -o wide

Install `rook <https://github.com/rook/rook>`_ - File, Block, and Object Storage Services for your Cloud-Native Environment

.. code-block:: shell-session

   $ helm repo add rook-master https://charts.rook.io/master
   $ helm install rook-master/rook --wait --namespace rook-system --name my-rook --version $(helm search rook | awk "/^rook/ { print \$2 }")

Create your Rook cluster

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-cluster.yaml

Running the Toolbox with ceph commands

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-tools.yaml

Create a storage class based on the Ceph RBD volume plugin

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-storageclass.yaml

Create a shared file system which can be mounted read-write from multiple pods

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-filesystem.yaml
   $ sleep 150

Check the status of your Ceph installation

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph status
   $ kubectl -n rook exec rook-tools -- ceph osd status

Check health detail of Ceph cluster

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph health detail

Check monitor quorum status of Ceph

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph quorum_status --format json-pretty

Dump monitoring information from Ceph

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph mon dump

Check the cluster usage status

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph df

Check OSD usage of Ceph

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph osd df

Check the Ceph monitor, OSD, pool, and placement group stats

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph mon stat
   $ kubectl -n rook exec rook-tools -- ceph osd stat
   $ kubectl -n rook exec rook-tools -- ceph osd pool stats
   $ kubectl -n rook exec rook-tools -- ceph pg stat

List the placement group

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph pg dump

List the Ceph pools in detail

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph osd pool ls detail

Check the CRUSH map view of OSDs

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph osd tree

List the cluster authentication keys

.. code-block:: shell-session

   $ kubectl -n rook exec rook-tools -- ceph auth list

Install `Prometheus <https://github.com/coreos/prometheus-operator>`_ - Prometheus Operator creates/configures/manages Prometheus clusters atop Kubernetes

.. code-block:: shell-session

   $ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
   $ helm install coreos/prometheus-operator --wait --name my-prometheus-operator --namespace monitoring
   $ helm install coreos/kube-prometheus --name my-kube-prometheus --namespace monitoring --set alertmanager.ingress.enabled=true,alertmanager.ingress.hosts[0]=alertmanager.domain.com,alertmanager.storageSpec.volumeClaimTemplate.spec.storageClassName=rook-block,alertmanager.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce,alertmanager.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi,grafana.adminPassword=admin123,grafana.ingress.enabled=true,grafana.ingress.hosts[0]=grafana.domain.com,prometheus.ingress.enabled=true,prometheus.ingress.hosts[0]=prometheus.domain.com,prometheus.storageSpec.volumeClaimTemplate.spec.storageClassName=rook-block,prometheus.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce,prometheus.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi
   $ GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring kube-prometheus-grafana -o jsonpath="{.data.password}" | base64 --decode ; echo)
   $ echo "Grafana login: admin / $GRAFANA_PASSWORD"

Install `Heapster <https://github.com/kubernetes/heapster>`_ - Compute Resource Usage Analysis and Monitoring of Container Clusters

.. code-block:: shell-session

   $ helm install stable/heapster --name my-heapster --set rbac.create=true

Install `Kubernetes Dashboard <https://github.com/kubernetes/dashboard>`_ - General-purpose web UI for Kubernetes clusters

.. code-block:: shell-session

   $ helm install stable/kubernetes-dashboard --name=my-kubernetes-dashboard --namespace monitoring --set ingress.enabled=true,rbac.clusterAdminRole=true
