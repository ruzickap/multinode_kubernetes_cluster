Labels, annotations, selectors
==============================

Create app1-prod deployment with labels (creates also Deployment)

.. code-block:: shell-session

   $ kubectl run app1-prod --image=gcr.io/kuar-demo/kuard-amd64:1 --replicas=3 --port=8080 --labels="ver=1,myapp=app1,env=prod"

Create service (only routable inside cluster).
The service is assigned Cluster IP (DNS record is automatically created) which load-balance across all of the pods that are identified by the selector

.. code-block:: shell-session

   $ kubectl expose deployment app1-prod

Create app1-test deployment

.. code-block:: shell-session

   $ kubectl run app1-test --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=1 --labels="ver=2,myapp=app1,env=test"

Create app2-prod

.. code-block:: shell-session

   $ kubectl run app2-prod --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=2 --port=8080 --labels="ver=2,myapp=app2,env=prod"

Create service

.. code-block:: shell-session

   $ kubectl expose deployment app2-prod

Check if the DNS record was properly created for the Cluster IPs.
app2-prod [name of the service], myns [namespace that this service is in], svc [service], cluster.local. [base domain name for the cluster]

.. code-block:: shell-session

   $ kubectl run nslookup --rm -it --restart=Never --image=busybox -- nslookup app2-prod
   $ kubectl run nslookup --rm -it --restart=Never --image=busybox -- nslookup app2-prod.myns

Create app2-staging

.. code-block:: shell-session

   $ kubectl run app2-staging --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=1 --labels="ver=2,myapp=app2,env=staging"

Show deployments

.. code-block:: shell-session

   $ kubectl get deployments -o wide --show-labels

Change labels

.. code-block:: shell-session

   $ kubectl label deployments app1-test "canary=true"

Add annotation - usually longer than labels

.. code-block:: shell-session

   $ kubectl annotate deployments app1-test description="My favorite deployment with my app"

List 'canary' deployments (with canary label)

.. code-block:: shell-session

   $ kubectl get deployments -o wide --label-columns=canary

Remove label

.. code-block:: shell-session

   $ kubectl label deployments app1-test "canary-"

List pods including labels

.. code-block:: shell-session

   $ kubectl get pods --sort-by=.metadata.name --show-labels

List pods ver=2 using the --selector flag

.. code-block:: shell-session

   $ kubectl get pods --selector="ver=2" --show-labels

List pods with 2 tags

.. code-block:: shell-session

   $ kubectl get pods --selector="myapp=app2,ver=2" --show-labels

List pods where myapp=(app1 or app2)

.. code-block:: shell-session

   $ kubectl get pods --selector="myapp in (app1,app2)" --show-labels

Label multiple pods

.. code-block:: shell-session

   $ kubectl label pods -l canary=true my=testlabel

List all services

.. code-block:: shell-session

   $ kubectl get services -o wide

Get service details

.. code-block:: shell-session

   $ kubectl describe service app1-prod

Get service endpoints

.. code-block:: shell-session

   $ kubectl describe endpoints app1-prod

List IPs belongs to specific pods

.. code-block:: shell-session

   $ kubectl get pods -o wide --selector=myapp=app1,env=prod --show-labels

Cleanup all deployments

.. code-block:: shell-session

   $ kubectl delete services,deployments -l myapp
