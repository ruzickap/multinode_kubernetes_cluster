Pods
====

Check 'kuard-pod.yaml' manifest which will run kuard application once it is imported to Kubernetes

.. code-block:: shell-session

   $ tee files/kuard-pod.yaml << EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: kuard
   spec:
     containers:
       - image: gcr.io/kuar-demo/kuard-amd64:1
         name: kuard
         ports:
           - containerPort: 8080
             name: http
             protocol: TCP
   EOF

Start pod from the pod manifest via Kubernetes API (see the 'ContainerCreating' status)

.. code-block:: shell-session

   $ kubectl apply --filename=files/kuard-pod.yaml; kubectl get pods
   $ sleep 40

List pods (-o yaml will print all details)

.. code-block:: shell-session

   $ kubectl get pods --namespace myns -o wide

Check pod details

.. code-block:: shell-session

   $ kubectl describe pods kuard

Get IP for a kuard pod

.. code-block:: shell-session

   $ kubectl get pods kuard -o jsonpath --template={.status.podIP}

Configure secure port-forwarding to access the specific pod exposed port using Kubernetes API
Access the pod by opening the web browser with url: http://127.0.0.1:8080 and http://127.0.0.1:8080/fs/{etc,var,home}

.. code-block:: shell-session

   $ kubectl port-forward kuard 8080:8080 &

Stop port forwarding

.. code-block:: shell-session

   $ pkill -f "kubectl port-forward kuard 8080:8080"

Get the logs from pod (-f for tail) (--previous will get logs from a previous instance of the container)

.. code-block:: shell-session

   $ kubectl logs kuard

Copy files to/from containers running in the pod

.. code-block:: shell-session

   $ kubectl cp --container=kuard /etc/os-release kuard:/tmp/

Run commands in your container with exec (-it for interactive session).
Check if I am in container

.. code-block:: shell-session

   $ kubectl exec kuard -- cat /etc/os-release

Delete pod - see the status 'Terminating'

.. code-block:: shell-session

   $ kubectl delete pods/kuard; kubectl get pods
   $ sleep 30

Check pods - the kuard should disappear form the 'pod list'

.. code-block:: shell-session

   $ kubectl get pods
