Health Checks
=============

Check 'kuard-pod-health.yaml' manifest which will start kuard and configure HTTP health check

.. code-block:: shell-session

   $ tee files/kuard-pod-health.yaml << EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: kuard
   spec:
     volumes:
       - name: "kuard-data"
         hostPath:
           path: "/var/lib/kuard"
     containers:
       - image: gcr.io/kuar-demo/kuard-amd64:1
         name: kuard
         volumeMounts:
           - mountPath: "/data"
             name: "kuard-data"
         ports:
           - containerPort: 8080
             name: http
             protocol: TCP
         resources:
           requests:
             cpu: "100m"
             memory: "128Mi"
           limits:
             cpu: "1000m"
             memory: "256Mi"
         # Pod must be ready, before Kubernetes start sending traffic to it
         readinessProbe:
           httpGet:
             path: /ready
             port: 8080
           # Check is done every 2 seconds starting as soon as the pod comes up
           periodSeconds: 2
           # Start checking once pod is up
           initialDelaySeconds: 0
           # If three successive checks fail, then the pod will be considered not ready.
           failureThreshold: 3
           # If only one check succeeds, then the pod will again be considered ready.
           successThreshold: 1
         livenessProbe:
           httpGet:
             path: /healthy
             port: 8080
           # Start probe 5 seconds after all the containers in the Pod are created
           initialDelaySeconds: 5
           # The response must be max in 1 second and status HTTP code must be between 200 and 400
           timeoutSeconds: 1
           # Repeat every 10 seconds
           periodSeconds: 10
           # If more than 3 probes failed - the container will fail + restart
           failureThreshold: 3
   EOF

Create a Pod using this manifest and then port-forward to that pod

.. code-block:: shell-session

   $ kubectl apply -f files/kuard-pod-health.yaml
   $ sleep 30

Point your browser to http://127.0.0.1:8080 then click 'Liveness Probe' tab and then 'fail' link - it will cause to fail health checks

.. code-block:: shell-session

   $ kubectl port-forward kuard 8080:8080 &

Stop port forwarding

.. code-block:: shell-session

   $ pkill -f "kubectl port-forward kuard 8080:8080"

You will see 'unhealthy' messages in the in the following output

.. code-block:: shell-session

   $ kubectl describe pods kuard | tail

Delete pod

.. code-block:: shell-session

   $ kubectl delete pods/kuard
   $ sleep 10
