Kubernetes Basics
=================

Create directory where the files will be stored

.. code-block:: shell-session

   $ mkdir files

Enable bash-completion for kubectl (bash-completion needs to be installed)

.. code-block:: shell-session

   $ source <(kubectl completion bash)

Check the cluster status (if it is healthy)

.. code-block:: shell-session

   $ kubectl get componentstatuses

List all namespaces

.. code-block:: shell-session

   $ kubectl get namespaces

Create namespace 'myns'

.. code-block:: shell-session

   $ kubectl create namespace myns

Change default namespace for current context

.. code-block:: shell-session

   $ kubectl config set-context $(kubectl config current-context) --namespace=myns

List out all of the nodes in our cluster

.. code-block:: shell-session

   $ kubectl get pods -o wide --all-namespaces --show-labels --sort-by=.metadata.name

Get more details about a specific node

.. code-block:: shell-session

   $ kubectl describe node $(kubectl get node --output=jsonpath="{.items[0].metadata.name}")
