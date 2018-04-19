Endpoints
=========

Show external service DNS definition

.. code-block:: shell-session

   $ tee files/dns-service.yaml << EOF
   kind: Service
   apiVersion: v1
   metadata:
     name: external-database
   spec:
     type: ExternalName
     externalName: database.company.com
   EOF

Create DNS name (CNAME) that points to the specific server running the database

.. code-block:: shell-session

   $ kubectl create -f files/dns-service.yaml

Show services

.. code-block:: shell-session

   $ kubectl get service

Remove service

.. code-block:: shell-session

   $ kubectl delete service external-database
