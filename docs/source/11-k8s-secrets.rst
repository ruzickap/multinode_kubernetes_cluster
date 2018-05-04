Secrets
=======

Download certificates

.. code-block:: shell-session

   $ wget -q -c -P files https://storage.googleapis.com/kuar-demo/kuard.crt https://storage.googleapis.com/kuar-demo/kuard.key

Create a secret named kuard-tls

.. code-block:: shell-session

   $ kubectl create secret generic kuard-tls --from-file=files/kuard.crt --from-file=files/kuard.key

Get details about created secret

.. code-block:: shell-session

   $ kubectl describe secrets kuard-tls

Show secrets

.. code-block:: shell-session

   $ kubectl get secrets

Update secrets - generate yaml and then edit the secret 'kubectl edit configmap my-config'

.. code-block:: shell-session

   $ kubectl create secret generic kuard-tls --from-file=files/kuard.crt --from-file=files/kuard.key --dry-run -o yaml | kubectl replace -f -

Create a new pod with secret attached

.. code-block:: shell-session

   $ tee files/kuard-secret.yaml << EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: kuard-tls
   spec:
     containers:
       - name: kuard-tls
         image: gcr.io/kuar-demo/kuard-amd64:1
         imagePullPolicy: Always
         volumeMounts:
         - name: tls-certs
           mountPath: "/tls"
           readOnly: true
     volumes:
       - name: tls-certs
         secret:
           secretName: kuard-tls
   EOF

Apply the config file

.. code-block:: shell-session

   $ kubectl apply -f files/kuard-secret.yaml
   $ sleep 20

Set port-forwarding. Go to https://localhost:8080, check the certificate and click on "File system browser" tab (/tls)

.. code-block:: shell-session

   $ kubectl port-forward kuard-tls 8443:8443 &

Stop port forwarding

.. code-block:: shell-session

   $ pkill -f "kubectl port-forward kuard-tls 8443:8443"

Delete pod

.. code-block:: shell-session

   $ kubectl delete pod kuard-tls
