Jobs
====

One-shot Jobs provide a way to run a single Pod once until successful termination.
Pod is restarted in case of failure

.. code-block:: shell-session

   $ kubectl run -it oneshot --image=gcr.io/kuar-demo/kuard-amd64:1 --restart=OnFailure -- --keygen-enable --keygen-exit-on-complete --keygen-num-to-gen 5

List all jobs

.. code-block:: shell-session

   $ kubectl get jobs -o wide

Delete job

.. code-block:: shell-session

   $ kubectl delete jobs oneshot

Show one-shot Job configuration file

.. code-block:: shell-session

   $ tee files/job-oneshot.yaml << EOF
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: oneshot
     labels:
       chapter: jobs
   spec:
     template:
       metadata:
         labels:
           chapter: jobs
       spec:
         containers:
         - name: kuard
           image: gcr.io/kuar-demo/kuard-amd64:1
           imagePullPolicy: Always
           args:
           - "--keygen-enable"
           - "--keygen-exit-on-complete"
           - "--keygen-num-to-gen=5"
         restartPolicy: OnFailure
   EOF

Create one-shot Job using a configuration file

.. code-block:: shell-session

   $ kubectl apply -f files/job-oneshot.yaml
   $ sleep 30

Print details about the job

.. code-block:: shell-session

   $ kubectl describe jobs oneshot

Get pod name of a job called 'oneshot' and check the logs

.. code-block:: shell-session

   $ POD_NAME=$(kubectl get pods --selector="job-name=oneshot" -o=jsonpath="{.items[0].metadata.name}")
   $ kubectl logs ${POD_NAME}

Remove job oneshot

.. code-block:: shell-session

   $ kubectl delete jobs oneshot

Show one-shot Job configuration file.
See the keygen-exit-code parameter - nonzero exit code after generating three keys

.. code-block:: shell-session

   $ tee files/job-oneshot-failure1.yaml << EOF
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: oneshot
     labels:
       chapter: jobs
   spec:
     template:
       metadata:
         labels:
           chapter: jobs
       spec:
         containers:
         - name: kuard
           image: gcr.io/kuar-demo/kuard-amd64:1
           imagePullPolicy: Always
           args:
           - "--keygen-enable"
           - "--keygen-exit-on-complete"
           - "--keygen-exit-code=1"
           - "--keygen-num-to-gen=3"
         restartPolicy: OnFailure
   EOF

Create one-shot Job using a configuration file

.. code-block:: shell-session

   $ kubectl apply -f files/job-oneshot-failure1.yaml
   $ sleep 60

Get pod status - look for CrashLoopBackOff/Error indicating pod restarts

.. code-block:: shell-session

   $ kubectl get pod -l job-name=oneshot

Remove the job

.. code-block:: shell-session

   $ kubectl delete jobs oneshot

Show Parallel Job configuration file - generate (5x10) keys generated in 5 containers

.. code-block:: shell-session

   $ tee files/job-parallel.yaml << EOF
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: parallel
     labels:
       chapter: jobs
   spec:
     # 5 pods simlutaneously
     parallelism: 5
     # repeat task 10 times
     completions: 10
     template:
       metadata:
         labels:
           chapter: jobs
       spec:
         containers:
         - name: kuard
           image: gcr.io/kuar-demo/kuard-amd64:1
           imagePullPolicy: Always
           args:
           - "--keygen-enable"
           - "--keygen-exit-on-complete"
           - "--keygen-num-to-gen=5"
         restartPolicy: OnFailure
   EOF

Create Parallel Job using a configuration file

.. code-block:: shell-session

   $ kubectl apply -f files/job-parallel.yaml

Check the pods and list changes as they happen

.. code-block:: shell-session

   $ kubectl get pods --watch -o wide &
   $ sleep 10

Stop the port forwarding

.. code-block:: shell-session

   $ pkill -f "kubectl get pods --watch -o wide"

Remove the job

.. code-block:: shell-session

   $ kubectl delete jobs parallel


Queue job example
-----------------

Memory-based work queue system: Producer -> Work Queue -> Consumers diagram

.. code-block:: shell-session

   $ tee /tmp/producer_queue_consumer-diagram.txt << EOF
                                                       +--------------+
                                                       |              |
                                                   +-> |   Consumer   |
                                                   |   |              |
                                                   |   +--------------+
                                                   |
   +--------------+          +----------------+    |   +--------------+
   |              |          |                |    |   |              |
   |   Producer   | +------> |   Work Queue   | +--+-> |   Consumer   |
   |              |          |                |    |   |              |
   +--------------+          +----------------+    |   +--------------+
                                                   |
                                                   |   +--------------+
                                                   |   |              |
                                                   +-> |   Consumer   |
                                                       |              |
                                                       +--------------+
   EOF

Create a simple ReplicaSet to manage a singleton work queue daemon

.. code-block:: shell-session

   $ tee files/rs-queue.yaml << EOF
   apiVersion: extensions/v1beta1
   kind: ReplicaSet
   metadata:
     labels:
       app: work-queue
       component: queue
       chapter: jobs
     name: queue
   spec:
     replicas: 1
     template:
       metadata:
         labels:
           app: work-queue
           component: queue
           chapter: jobs
       spec:
         containers:
         - name: queue
           image: "gcr.io/kuar-demo/kuard-amd64:1"
           imagePullPolicy: Always
   EOF

Create work queue using a configuration file

.. code-block:: shell-session

   $ kubectl apply -f files/rs-queue.yaml
   $ sleep 30

Configure port forwarding to connect to the 'work queue daemon' pod

.. code-block:: shell-session

   $ QUEUE_POD=$(kubectl get pods -l app=work-queue,component=queue -o jsonpath="{.items[0].metadata.name}")
   $ kubectl port-forward $QUEUE_POD 8080:8080 &

Expose work queue - this helps consumers+producers to locate the work queue via DNS

.. code-block:: shell-session

   $ tee files/service-queue.yaml << EOF
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       app: work-queue
       component: queue
       chapter: jobs
     name: queue
   spec:
     ports:
     - port: 8080
       protocol: TCP
       targetPort: 8080
     selector:
       app: work-queue
       component: queue
   EOF

Create the service pod using a configuration file

.. code-block:: shell-session

   $ kubectl apply -f files/service-queue.yaml
   $ sleep 20

Create a work queue called 'keygen'

.. code-block:: shell-session

   $ curl -X PUT 127.0.0.1:8080/memq/server/queues/keygen

Create work items and load up the queue

.. code-block:: shell-session

   $ for WORK in work-item-{0..20}; do curl -X POST 127.0.0.1:8080/memq/server/queues/keygen/enqueue -d "$WORK"; done

Queue should not be empty - check the queue by looking at the 'MemQ Server' tab in Web interface (http://127.0.0.1:8080/-/memq)

.. code-block:: shell-session

   $ curl --silent 127.0.0.1:8080/memq/server/stats | jq

Show consumer job config file allowing start up five pods in parallel.
Once the first pod exits with a zero exit code, the Job will not start any new pods (none of the workers should exit until the work is done)

.. code-block:: shell-session

   $ tee files/job-consumers.yaml << EOF
   apiVersion: batch/v1
   kind: Job
   metadata:
     labels:
       app: message-queue
       component: consumer
       chapter: jobs
     name: consumers
   spec:
     parallelism: 5
     template:
       metadata:
         labels:
           app: message-queue
           component: consumer
           chapter: jobs
       spec:
         containers:
         - name: worker
           image: "gcr.io/kuar-demo/kuard-amd64:1"
           imagePullPolicy: Always
           args:
           - "--keygen-enable"
           - "--keygen-exit-on-complete"
           - "--keygen-memq-server=http://queue:8080/memq/server"
           - "--keygen-memq-queue=keygen"
         restartPolicy: OnFailure
   EOF

Create consumer job from config file

.. code-block:: shell-session

   $ kubectl apply -f files/job-consumers.yaml
   $ sleep 30

Five pods should be created to run until the work queue is empty.
Open the web browser to see changing queue status (http://127.0.0.1:8080/-/memq)

.. code-block:: shell-session

   $ kubectl get pods -o wide

Check the queue status - especially the 'dequeued' and 'depth' fields

.. code-block:: shell-session

   $ curl --silent 127.0.0.1:8080/memq/server/stats | jq

Stop port-forwarding

.. code-block:: shell-session

   $ pkill -f "kubectl port-forward $QUEUE_POD 8080:8080"

Clear the resources

.. code-block:: shell-session

   $ kubectl delete rs,svc,job -l chapter=jobs
