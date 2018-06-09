Helm Installation
=================

Helm installation: https://github.com/kubernetes/helm/blob/master/docs/rbac.md

.. code-block:: shell-session

   $ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
   $ kubectl create serviceaccount tiller --namespace kube-system
   $ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
   $ helm init --wait --service-account tiller
   $ helm repo update

Install `Traefik <https://github.com/containous/traefik>`_ - Træfik is a modern HTTP reverse proxy and load balancer

.. code-block:: shell-session

   $ helm install stable/traefik --wait --name my-traefik --namespace kube-system --set serviceType=NodePort,dashboard.enabled=true,accessLogs.enabled=true,rbac.enabled=true,metrics.prometheus.enabled=true
   $ kubectl describe svc my-traefik --namespace kube-system

Install `rook <https://github.com/rook/rook>`_ - File, Block, and Object Storage Services for your Cloud-Native Environment

.. code-block:: shell-session

   $ helm repo add rook-master https://charts.rook.io/master
   $ helm install rook-master/rook-ceph --wait --namespace rook-ceph-system --name my-rook --version $(helm search rook-ceph | awk "/^rook-master/ { print \$2 }")

Create your Rook cluster

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/cluster.yaml

Running the Toolbox with ceph commands

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml

Create a storage class based on the Ceph RBD volume plugin

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/storageclass.yaml

Create a shared file system which can be mounted read-write from multiple pods

.. code-block:: shell-session

   $ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/filesystem.yaml
   $ sleep 150

Check the status of your Ceph installation

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph status
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd status

Check health detail of Ceph cluster

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph health detail

Check monitor quorum status of Ceph

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph quorum_status --format json-pretty

Dump monitoring information from Ceph

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph mon dump

Check the cluster usage status

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph df

Check OSD usage of Ceph

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd df

Check the Ceph monitor, OSD, pool, and placement group stats

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph mon stat
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd stat
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd pool stats
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph pg stat

List the Ceph pools in detail

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd pool ls detail

Check the CRUSH map view of OSDs

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd tree

List the cluster authentication keys

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph auth list

Change the size of Ceph replica for "replicapool" pool

.. code-block:: shell-session

   $ kubectl get pool --namespace=rook-ceph replicapool -o yaml | sed "s/size: 1/size: 3/" | kubectl replace -f -

List details for "replicapool"

.. code-block:: shell-session

   $ kubectl describe pool --namespace=rook-ceph replicapool

See the manifest of the pod which should use rook/ceph

.. code-block:: shell-session

   $ tee files/rook-ceph-test-job.yaml << EOF
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: rook-ceph-test-pv-claim
   spec:
     storageClassName: rook-ceph-block
     accessModes:
     - ReadWriteOnce
     resources:
       requests:
         storage: 1Gi
   ---
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: rook-ceph-test
     labels:
       app: rook-ceph-test
   spec:
     template:
       metadata:
         labels:
           app: rook-ceph-test
       spec:
         containers:
         - name: rook-ceph-test
           image: busybox
           command: [ 'dd', 'if=/dev/zero', 'of=/data/zero_file', 'bs=1M', 'count=100' ]
           volumeMounts:
             - name: rook-ceph-test
               mountPath: "/data"
         restartPolicy: Never
         volumes:
         - name: rook-ceph-test
           persistentVolumeClaim:
             claimName: rook-ceph-test-pv-claim
   EOF

Check the ceph usage

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd status
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph df
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd df

Apply the manifest

.. code-block:: shell-session

   $ kubectl apply -f files/rook-ceph-test-job.yaml
   $ sleep 10

Check the ceph usage again

.. code-block:: shell-session

   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd status
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph df
   $ kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd df

List the Persistent Volume Claims

.. code-block:: shell-session

   $ kubectl get pvc

Delete the job

.. code-block:: shell-session

   $ kubectl delete job rook-ceph-test


Install `Prometheus <https://github.com/coreos/prometheus-operator>`_ - Prometheus Operator creates/configures/manages Prometheus clusters atop Kubernetes

.. code-block:: shell-session

   $ helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
   $ helm install coreos/prometheus-operator --wait --name my-prometheus-operator --namespace monitoring
   $ helm install coreos/kube-prometheus --name my-kube-prometheus --namespace monitoring --set alertmanager.ingress.enabled=true,alertmanager.ingress.hosts[0]=alertmanager.domain.com,alertmanager.storageSpec.volumeClaimTemplate.spec.storageClassName=rook-block,alertmanager.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce,alertmanager.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi,grafana.adminPassword=admin123,grafana.ingress.enabled=true,grafana.ingress.hosts[0]=grafana.domain.com,prometheus.ingress.enabled=true,prometheus.ingress.hosts[0]=prometheus.domain.com,prometheus.storageSpec.volumeClaimTemplate.spec.storageClassName=rook-block,prometheus.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce,prometheus.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi
   $ GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring my-kube-prometheus-grafana -o jsonpath="{.data.password}" | base64 --decode ; echo)
   $ echo "Grafana login: admin / $GRAFANA_PASSWORD"

Install `Heapster <https://github.com/kubernetes/heapster>`_ - Compute Resource Usage Analysis and Monitoring of Container Clusters

.. code-block:: shell-session

   $ helm install stable/heapster --name my-heapster --set rbac.create=true

Install `Kubernetes Dashboard <https://github.com/kubernetes/dashboard>`_ - General-purpose web UI for Kubernetes clusters

.. code-block:: shell-session

   $ helm install stable/kubernetes-dashboard --name=my-kubernetes-dashboard --namespace monitoring --set ingress.enabled=true,rbac.clusterAdminRole=true
