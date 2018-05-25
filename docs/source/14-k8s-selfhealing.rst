Self-Healing
============

Get pod details

.. code-block:: shell-session

   $ kubectl get pods -o wide

Get first nginx pod and delete it - one of the nginx pods should be in 'Terminating' status

.. code-block:: shell-session

   $ NGINX_POD=$(kubectl get pods -l app=nginx --output=jsonpath="{.items[0].metadata.name}")
   $ kubectl delete pod $NGINX_POD; kubectl get pods -l app=nginx -o wide
   $ sleep 10

Get pod details - one nginx pod should be freshly started

.. code-block:: shell-session

   $ kubectl get pods -l app=nginx -o wide

Get deployement details and check the events for recent changes

.. code-block:: shell-session

   $ kubectl describe deployment nginx-deployment

Halt one of the nodes (node2)

.. code-block:: shell-session

   $ vagrant halt node2
   $ sleep 30

Get node details - node2 Status=NotReady

.. code-block:: shell-session

   $ kubectl get nodes

Get pod details - everything looks fine - you need to wait 5 minutes

.. code-block:: shell-session

   $ kubectl get pods -o wide

Pod will not be evicted until it is 5 minutes old -  (see Tolerations in 'describe pod' ).
It prevents Kubernetes to spin up the new containers when it is not necessary

.. code-block:: shell-session

   $ NGINX_POD=$(kubectl get pods -l app=nginx --output=jsonpath="{.items[0].metadata.name}")
   $ kubectl describe pod $NGINX_POD | grep -A1 Tolerations

Sleeping for 5 minutes

.. code-block:: shell-session

   $ sleep 300

Get pods details - Status=Unknown/NodeLost and new container was started

.. code-block:: shell-session

   $ kubectl get pods -o wide

Get depoyment details - again AVAILABLE=3/3

.. code-block:: shell-session

   $ kubectl get deployments -o wide

Power on the node2 node

.. code-block:: shell-session

   $ vagrant up node2
   $ sleep 70

Get node details - node2 should be Ready again

.. code-block:: shell-session

   $ kubectl get nodes

Get pods details - 'Unknown' pods were removed

.. code-block:: shell-session

   $ kubectl get pods -o wide
