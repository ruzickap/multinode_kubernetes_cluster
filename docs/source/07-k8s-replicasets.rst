ReplicaSet
==========

Show minimal ReplicaSet definition

.. code-block:: shell-session

   $ tee files/kuard-rs.yaml << EOF
   apiVersion: extensions/v1beta1
   kind: ReplicaSet
   metadata:
     name: kuard
   spec:
     replicas: 1
     template:
       metadata:
         labels:
           app: kuard
           version: "2"
       spec:
         containers:
           - name: kuard
             image: "gcr.io/kuar-demo/kuard-amd64:2"
   EOF

Create ReplicaSet

.. code-block:: shell-session

   $ kubectl apply -f files/kuard-rs.yaml

Check pods

.. code-block:: shell-session

   $ kubectl get pods

Check ReplicaSet details

.. code-block:: shell-session

   $ kubectl describe rs kuard

The pods have the same labels as ReplicaSet

.. code-block:: shell-session

   $ kubectl get pods -l app=kuard,version=2 --show-labels

Check if pod is part of ReplicaSet

.. code-block:: shell-session

   $ kubectl get pods -l app=kuard,version=2 -o json | jq ".items[].metadata"

Scale up ReplicaSet

.. code-block:: shell-session

   $ kubectl scale replicasets kuard --replicas=4

New pods are beeing created

.. code-block:: shell-session

   $ kubectl get pods -l app=kuard --show-labels

Delete ReplicaSet

.. code-block:: shell-session

   $ kubectl delete rs kuard
