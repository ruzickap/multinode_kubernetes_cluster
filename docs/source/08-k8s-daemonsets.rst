DaemonSets and NodeSelector
===========================

Add labels to your nodes (hosts)

.. code-block:: shell-session

   $ kubectl label nodes node{2,4} ssd=true

Filter nodes based on labels

.. code-block:: shell-session

   $ kubectl get nodes --selector ssd=true

Check 'nginx-fast-storage.yaml' which will provision nginx to ssd labeled nodes only.
By default a DaemonSet will create a copy of a Pod on every node

.. code-block:: shell-session

   $ tee files/nginx-fast-storage.yaml << EOF
   apiVersion: extensions/v1beta1
   kind: "DaemonSet"
   metadata:
     labels:
       app: nginx
       ssd: "true"
     name: nginx-fast-storage
   spec:
     template:
       metadata:
         labels:
           app: nginx
           ssd: "true"
       spec:
         nodeSelector:
           ssd: "true"
         containers:
           - name: nginx
             image: nginx:1.10.0
   EOF

Create daemonset from the nginx-fast-storage.yaml

.. code-block:: shell-session

   $ kubectl apply -f files/nginx-fast-storage.yaml

Check the nodes where nginx was deployed

.. code-block:: shell-session

   $ kubectl get pods -o wide

Add label ssd=true to the node3 - nginx should be deployed there automatically

.. code-block:: shell-session

   $ kubectl label nodes node3 ssd=true

Check the nodes where nginx was deployed

.. code-block:: shell-session

   $ kubectl get pods -o wide

Check the nodes where nginx was deployed

.. code-block:: shell-session

   $ kubectl delete ds nginx-fast-storage
