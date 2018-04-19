ConfigMaps
==========

Show file with key/value pairs which will be available to the pod

.. code-block:: shell-session

   $ tee files/my-config.txt << EOF
   # This is a sample config file that I might use to configure an application
   parameter1 = value1
   parameter2 = value2
   EOF

Create a ConfigMap with that file (environment variables are specified with a special valueFrom member)

.. code-block:: shell-session

   $ kubectl create configmap my-config --from-file=files/my-config.txt --from-literal=extra-param=extra-value --from-literal=another-param=another-value

Show ConfigMaps

.. code-block:: shell-session

   $ kubectl get configmaps

Show ConfigMap details

.. code-block:: shell-session

   $ kubectl describe configmap my-config

See the YAML ConfigMap object

.. code-block:: shell-session

   $ kubectl get configmaps my-config -o yaml

Prepare config file for ConfigMap usage

.. code-block:: shell-session

   $ tee files/kuard-config.yaml << \EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: kuard-config
   spec:
     containers:
       - name: test-container
         image: gcr.io/kuar-demo/kuard-amd64:1
         imagePullPolicy: Always
         command:
           - "/kuard"
           - "$(EXTRA_PARAM)"
         env:
           - name: ANOTHER_PARAM
             valueFrom:
               configMapKeyRef:
                 name: my-config
                 key: another-param
           # Define the environment variable
           - name: EXTRA_PARAM
             valueFrom:
               configMapKeyRef:
                 # The ConfigMap containing the value you want to assign to ANOTHER_PARAM
                 name: my-config
                 # Specify the key associated with the value
                 key: extra-param
         volumeMounts:
           - name: config-volume
             mountPath: /config
     volumes:
       - name: config-volume
         configMap:
           name: my-config
     restartPolicy: Never
   EOF

Apply the config file

.. code-block:: shell-session

   $ kubectl apply -f files/kuard-config.yaml
   $ sleep 10

{EXTRA_PARAM,ANOTHER_PARAM} variable has value from configmap my-config/{extra-param,another-param} and file /config/my-config.txt exists in container

.. code-block:: shell-session

   $ kubectl exec kuard-config -- sh -xc "echo EXTRA_PARAM: \$EXTRA_PARAM; echo ANOTHER_PARAM: \$ANOTHER_PARAM && cat /config/my-config.txt"

Go to http://localhost:8080 and click on the 'Server Env' tab, then 'File system browser' tab (/config) and look for ANOTHER_PARAM and EXTRA_PARAM values

.. code-block:: shell-session

   $ kubectl port-forward kuard-config 8080:8080 &

Stop port forwarding

.. code-block:: shell-session

   $ pkill -f "kubectl port-forward kuard-config 8080:8080"

Remove pod"

.. code-block:: shell-session

   $ kubectl delete pod kuard-config
