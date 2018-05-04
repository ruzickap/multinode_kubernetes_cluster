Notes
=====

Show logs from specific docker container inside pod

.. code-block:: shell-session

   $ kubectl logs --namespace=kube-system $(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name) --container=dnsmasq --tail=10
   $ kubectl logs --namespace=kube-system $(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name) --container=kubedns --tail=10

See the logs directly on the Kubernetes node

.. code-block:: shell-session

   $ ssh $SSH_ARGS vagrant@node1 "ls /var/log/containers/"

Show all

.. code-block:: shell-session

   $ kubectl get all
