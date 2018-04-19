Deployments
===========

Show nginx deployment definition

.. code-block:: shell-session

   $ tee files/nginx-deployment.yaml << EOF
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deployment
     labels:
       app: nginx
   spec:
     selector:
       matchLabels:
         app: nginx
     replicas: 3
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
         - name: nginx
           image: nginx:1.7.9
           ports:
           - containerPort: 80
   EOF

Create nginx deployment

.. code-block:: shell-session

   $ kubectl create -f files/nginx-deployment.yaml

List deployments

.. code-block:: shell-session

   $ kubectl get deployments -o wide

Get deployment details

.. code-block:: shell-session

   $ kubectl describe deployment nginx-deployment

Show deployment YAML file (look for: 'nginx:1.7.9')

.. code-block:: shell-session

   $ kubectl get deployment nginx-deployment -o wide

Change deployment image (version 1.7.9 -> 1.8) - you can do the change by running 'kubectl edit deployment nginx-deployment' too...

.. code-block:: shell-session

   $ kubectl set image deployment nginx-deployment nginx=nginx:1.8

See what is happening during the deployment change

.. code-block:: shell-session

   $ kubectl rollout status deployment nginx-deployment

Get deployment details (see: 'nginx:1.8')

.. code-block:: shell-session

   $ kubectl get deployment nginx-deployment -o wide

Show details for deployment

.. code-block:: shell-session

   $ kubectl describe deployment nginx-deployment

See the deployment history (first there was version nginx:1.7.9, then nginx:1.8)

.. code-block:: shell-session

   $ kubectl rollout history deployment nginx-deployment --revision=1
   $ kubectl rollout history deployment nginx-deployment --revision=2

Rollback the deployment to previous version (1.7.9)

.. code-block:: shell-session

   $ kubectl rollout undo deployment nginx-deployment
   $ kubectl rollout status deployment nginx-deployment

Get deployment details - see the image is now again 'nginx:1.7.9'

.. code-block:: shell-session

   $ kubectl get deployment nginx-deployment -o wide

Rollback the deployment back to version (1.8)

.. code-block:: shell-session

   $ kubectl rollout undo deployment nginx-deployment --to-revision=2
   $ kubectl rollout status deployment nginx-deployment

Get deployment details - see the image is now again 'nginx:1.8'

.. code-block:: shell-session

   $ kubectl get deployment nginx-deployment -o wide

Check the utilization of pods

.. code-block:: shell-session

   $ kubectl top pod --heapster-namespace=myns --all-namespaces --containers
