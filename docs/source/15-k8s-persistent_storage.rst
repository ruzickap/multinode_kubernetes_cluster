Persistent Storage
==================

Install and configure NFS on node1

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node1 "sudo sh -xc \" apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y nfs-kernel-server > /dev/null; mkdir /nfs; chown nobody:nogroup /nfs; echo /nfs *\(rw,sync,no_subtree_check\) >> /etc/exports; systemctl restart nfs-kernel-server \""

Install NFS client to other nodes

.. code-block:: shell-session

   $ for COUNT in {2..4}; do ssh $SSH_ARGS vagrant@node${COUNT} "sudo sh -xc \"apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y nfs-common > /dev/null\""; done

Show persistent volume object definition

.. code-block:: shell-session

   $ tee files/nfs-volume.yaml << EOF
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: nfs-pv
     labels:
       volume: nfs-volume
   spec:
     accessModes:
     - ReadWriteMany
     capacity:
       storage: 1Gi
     nfs:
       server: node1
       path: "/nfs"
   EOF

Create persistent volume

.. code-block:: shell-session

   $ kubectl create -f files/nfs-volume.yaml

Check persistent volumes

.. code-block:: shell-session

   $ kubectl get persistentvolume

Show persistent volume claim object definition

.. code-block:: shell-session

   $ tee files/nfs-volume-claim.yaml << EOF
   kind: PersistentVolumeClaim
   apiVersion: v1
   metadata:
     name: nfs-pvc
   spec:
     accessModes:
     - ReadWriteMany
     resources:
       requests:
         storage: 1Gi
     selector:
       matchLabels:
         volume: nfs-volume
   EOF

Claim the persistent volume for our pod

.. code-block:: shell-session

   $ kubectl create -f files/nfs-volume-claim.yaml

Check persistent volume claims

.. code-block:: shell-session

   $ kubectl get persistentvolumeclaim

Show replicaset definition

.. code-block:: shell-session

   $ tee files/nfs-test-replicaset.yaml << EOF
   apiVersion: apps/v1
   kind: ReplicaSet
   metadata:
     name: nfs-test
     # labels so that we can bind a service to this pod
     labels:
       app: nfs-test
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: nfs-test
     template:
       metadata:
         labels:
           app: nfs-test
       spec:
         containers:
         - name: nfs-test
           image: busybox
           command: [ 'sh', '-c', 'date >> /tmp/date && sleep 3600' ]
           volumeMounts:
             - name: nfs-test
               mountPath: "/tmp"
         volumes:
         - name: nfs-test
           persistentVolumeClaim:
             claimName: nfs-pvc
         securityContext:
           runAsUser: 65534
           fsGroup: 65534
   EOF



Create replicaset

.. code-block:: shell-session

   $ kubectl create -f files/nfs-test-replicaset.yaml
   $ sleep 20

You can see the /tmp is mounted to both pods containing the same file 'date'

.. code-block:: shell-session

   $ NFS_TEST_POD2=$(kubectl get pods --no-headers -l app=nfs-test -o custom-columns=NAME:.metadata.name | head -1); echo $NFS_TEST_POD2
   $ NFS_TEST_POD1=$(kubectl get pods --no-headers -l app=nfs-test -o custom-columns=NAME:.metadata.name | tail -1); echo $NFS_TEST_POD1
   $ kubectl exec -it $NFS_TEST_POD1 -- sh -xc "hostname; echo $NFS_TEST_POD1 >> /tmp/date"
   $ kubectl exec -it $NFS_TEST_POD2 -- sh -xc "hostname; echo $NFS_TEST_POD2 >> /tmp/date"

Show files on NFS server - there should be 'nfs/date' file with 2 dates

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node1 "set -x; ls -al /nfs -ls; ls -n /nfs; cat /nfs/date"
