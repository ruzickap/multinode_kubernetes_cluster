#!/usr/bin/env bash

################################################
# include the magic
################################################
test -f ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
. ./demo-magic.sh -n

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=1

# No wait
export NO_WAIT=true

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

# Check if kubeconfig.conf can be used
test -f $PWD/kubeconfig.conf || echo "*** Can not find Kubernetes config file: $PWD/kubeconfig.conf !!!"

# SSH default parameters
SSH_ARGS=" -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "

# The Kubernetes version
KUBERNETES_VERSION="1.10.0"

test -d files || mkdir files

# hide the evidence
clear


p  "# Enable bash-completion for kubectl (bash-completion needs to be installed)"
pe 'source <(kubectl completion bash)'

p  '# Use the correct kubeconfig'
pe 'export KUBECONFIG=$PWD/kubeconfig.conf'


p  ""
################################################
p  "*** Kubernetes basics"
################################################


p  "# Check the cluster status (if it is healthy)"
pe 'kubectl get componentstatuses'

p  ""
p  "# List all namespaces"
pe 'kubectl get namespaces'

p  ""
p  "# Create namespace 'myns'"
pe 'kubectl create namespace myns'

p  ""
p  "# Change default namespace for current context"
pe 'kubectl config set-context $(kubectl config current-context) --namespace=myns'

p  ""
p  "# List out all of the nodes in our cluster"
pe 'kubectl get pods -o wide --all-namespaces --show-labels --sort-by=.metadata.name'

p  ""
p  "# Get more details about a first node"
pe 'kubectl describe node $(kubectl get node --output=jsonpath="{.items[0].metadata.name}")'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Helm"
################################################


p  ""
p  "# Install Helm"
pe 'curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash'
pe 'kubectl create serviceaccount tiller --namespace kube-system'
pe 'kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller'
pe 'helm init --service-account tiller'
pe 'sleep 30'
pe 'helm repo update'


p  ""
################################################
p  "*** nginx-ingress"
################################################


p  ""
p  "# Install nginx-ingress"
pe 'helm install stable/nginx-ingress --wait --name my-nginx --set \
controller.daemonset.useHostPort=true,\
controller.kind=DaemonSet,\
controller.metrics.enabled=true,\
controller.service.type=NodePort,\
controller.stats.enabled=true,\
rbac.create=true,\
'
pe 'kubectl get pods --all-namespaces -l app=nginx-ingress -o wide'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** rook"
################################################


pe 'helm repo add rook-master https://charts.rook.io/master'
pe 'helm install rook-master/rook-ceph --wait --namespace rook-ceph-system --name my-rook --version $(helm search rook-ceph | awk "/^rook-master/ { print \$2 }")'
p  '# Create your Rook cluster'
pe 'kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/cluster.yaml'
p  '# Running the Toolbox with ceph commands'
pe 'kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml'
p  '# Create a storage class based on the Ceph RBD volume plugin'
pe 'kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/storageclass.yaml'
p  '# Create a shared file system which can be mounted read-write from multiple pods'
pe 'kubectl create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/filesystem.yaml'
pe 'sleep 150'

p  '# Check the status of your Ceph installation'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph status'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd status'

p  '# Check health detail of Ceph cluster'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph health detail'

p  '# Check monitor quorum status of Ceph'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph quorum_status --format json-pretty'

p  '# Dump monitoring information from Ceph'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph mon dump'

p  '# Check the cluster usage status'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph df'

p  '# Check OSD usage of Ceph'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd df'

p  '# Check the Ceph monitor, OSD, pool, and placement group stats'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph mon stat'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd stat'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd pool stats'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph pg stat'

p  '# List the placement group'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph pg dump'

p  '# List the Ceph pools in detail'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd pool ls detail'

p  'Check the CRUSH map view of OSDs'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd tree'

p  '# List the cluster authentication keys'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph auth list'

p  '# Change the size of Ceph replica for "replicapool" pool'
pe 'kubectl get pool --namespace=rook-ceph replicapool -o yaml | sed "s/size: 1/size: 3/" | kubectl replace -f -'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  '# List details for "replicapool"'
pe 'kubectl describe pool --namespace=rook-ceph replicapool'

cat > files/rook-ceph-test-job.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rook-ceph-test-pv-claim
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: batch/v1
kind: Job
metadata:
  name: rook-ceph-test
  labels:
    app: rook-ceph-test
spec:
  template:
    metadata:
      labels:
        app: rook-ceph-test
    spec:
      containers:
      - name: rook-ceph-test
        image: busybox
        command: [ 'dd', 'if=/dev/zero', 'of=/data/zero_file', 'bs=1M', 'count=100' ]
        volumeMounts:
          - name: rook-ceph-test
            mountPath: "/data"
      restartPolicy: Never
      volumes:
      - name: rook-ceph-test
        persistentVolumeClaim:
          claimName: rook-ceph-test-pv-claim
EOF

p  ""
p  "# See the manifest of the pod which should use rook/ceph"
pe 'cat files/rook-ceph-test-job.yaml'

p  '# Check the ceph usage'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd status'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph df'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd df'

p  ""
p  "# Apply the manifest"
pe 'kubectl apply -f files/rook-ceph-test-job.yaml'
pe 'sleep 10'

p  '# Check the ceph usage'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd status'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph df'
pe 'kubectl -n rook-ceph exec rook-ceph-tools -- ceph osd df'

p  ""
p  "# List the Persistent Volume Claims"
pe 'kubectl get pvc'

p  ""
p  "# Delete the job"
pe 'kubectl delete job rook-ceph-test'


p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** prometheus (and it's dependencies)"
################################################


p  ""
p  "# Install prometheus"
pe 'helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/'
pe 'helm install coreos/prometheus-operator --wait --name my-prometheus-operator --namespace monitoring'
pe 'helm install coreos/kube-prometheus --name my-kube-prometheus --namespace monitoring --set \
alertmanager.ingress.enabled=true,\
alertmanager.ingress.hosts[0]=alertmanager.domain.com,\
alertmanager.storageSpec.volumeClaimTemplate.spec.storageClassName=rook-block,\
alertmanager.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce,\
alertmanager.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi,\
grafana.adminPassword=admin123,\
grafana.ingress.enabled=true,\
grafana.ingress.hosts[0]=grafana.domain.com,\
prometheus.ingress.enabled=true,\
prometheus.ingress.hosts[0]=prometheus.domain.com,\
prometheus.storageSpec.volumeClaimTemplate.spec.storageClassName=rook-block,\
prometheus.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce,\
prometheus.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi,\
'

pe 'GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring my-kube-prometheus-grafana -o jsonpath="{.data.password}" | base64 --decode ; echo)'
pe 'echo "Grafana login: admin / $GRAFANA_PASSWORD"'


p  ""
################################################
p  "*** heapster"
################################################


p  ""
p  "# Install heapster"
pe 'helm install stable/heapster --name my-heapster --set rbac.create=true'


p  ""
################################################
p  "*** kubernetes-dashboard"
################################################


p  ""
p  "# Install kubernetes-dashboard"
pe 'helm install stable/kubernetes-dashboard --name=my-kubernetes-dashboard --namespace monitoring --set ingress.enabled=true,rbac.clusterAdminRole=true'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Run pods, enable port-forwarding, show pod logs, check status, get into the pod"
################################################


cat > files/kuard-pod.yaml << EOF
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

p  ""
p  "# Check 'kuard-pod.yaml' manifest which will run kuard application once it is imported to Kubernetes"
pe 'cat files/kuard-pod.yaml'

p  ""
p  "# Start pod from the pod manifest via Kubernetes API (see the 'ContainerCreating' status)"
pe 'kubectl apply --filename=files/kuard-pod.yaml; kubectl get pods'
pe 'sleep 40'

p  ""
p  "# List pods (-o yaml will print all details)"
pe 'kubectl get pods --namespace myns -o wide'

p  ""
p  "# Check pod details"
pe 'kubectl describe pods kuard'

p  ""
p  "# Get IP for a kuard pod"
pe 'kubectl get pods kuard -o jsonpath --template={.status.podIP}'

p  ""
p  "# Configure secure port-forwarding to access the specific pod exposed port using Kubernetes API"
p  "# Access the pod by opening the web browser with url: http://127.0.0.1:8080 and http://127.0.0.1:8080/fs/{etc,var,home}"
pe 'kubectl port-forward kuard 8080:8080 &'
p  " "
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Stop port forwarding"
pe 'pkill -f "kubectl port-forward kuard 8080:8080"'

p  ""
p  "# Get the logs from pod (-f for tail) (--previous will get logs from a previous instance of the container)"
pe 'kubectl logs kuard'

p  ""
p  "# Copy files to/from containers running in the pod"
pe 'kubectl cp --container=kuard /etc/os-release kuard:/tmp/'

p  ""
p  "# Run commands in your container with exec (-it for interactive session)"
p  "# Check if I am in container"
pe 'kubectl exec kuard -- cat /etc/os-release'

p  ""
p  "# Delete pod - see the status 'Terminating'"
pe 'kubectl delete pods/kuard; kubectl get pods'
pe 'sleep 30'

p  ""
p  "# Check pods - the kuard should disappear form the 'pod list'"
pe 'kubectl get pods'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Configure pod health checks / monitoring"
################################################


cat > files/kuard-pod-health.yaml << EOF
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

p  ""
p  "# Check 'kuard-pod-health.yaml' manifest which will start kuard and configure HTTP health check"
pe 'cat files/kuard-pod-health.yaml'

p  ""
p  "# Create a Pod using this manifest and then port-forward to that pod"
pe 'kubectl apply -f files/kuard-pod-health.yaml'
pe 'sleep 30'

p  ""
p  "# Point your browser to http://127.0.0.1:8080 then click 'Liveness Probe' tab and then 'fail' link - it will cause to fail health checks"
pe 'kubectl port-forward kuard 8080:8080 &'
p  " "
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Stop port forwarding"
pe 'pkill -f "kubectl port-forward kuard 8080:8080"'

p  ""
p  "# You will see 'unhealthy' messages in the in the following output"
pe 'kubectl describe pods kuard | tail'

p  ""
p  "# Delete pod"
pe 'kubectl delete pods/kuard'
pe 'sleep 10'


p  ""
################################################
p  "*** Set labels/annotations, filter labels"
################################################


p  ""
p  "# Create app1-prod deployment with labels (creates also Deployment)"
pe 'kubectl run app1-prod --image=gcr.io/kuar-demo/kuard-amd64:1 --replicas=3 --port=8080 --labels="ver=1,myapp=app1,env=prod"'

p  ""
p  "# Create service (only routable inside cluster)"
p  "# The service is assigned Cluster IP (DNS record is automatically created) which load-balance across all of the pods that are identified by the selector"
pe 'kubectl expose deployment app1-prod'

p  ""
p  "# Create app1-test deployment"
pe 'kubectl run app1-test --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=1 --labels="ver=2,myapp=app1,env=test"'

p  ""
p  "# Create app2-prod"
pe 'kubectl run app2-prod --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=2 --port=8080 --labels="ver=2,myapp=app2,env=prod"'

p  ""
p  "# Create service"
pe 'kubectl expose deployment app2-prod'

p  ""
p  "# Check if the DNS record was properly created for the Cluster IPs"
p  "# app2-prod [name of the service], myns [namespace that this service is in], svc [service], cluster.local. [base domain name for the cluster]"
pe 'kubectl run nslookup --rm -it --restart=Never --image=busybox -- nslookup app2-prod'
pe 'kubectl run nslookup --rm -it --restart=Never --image=busybox -- nslookup app2-prod.myns'

p  ""
p  "# Create app2-staging"
pe 'kubectl run app2-staging --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=1 --labels="ver=2,myapp=app2,env=staging"'

p  ""
p  "# Show deployments"
pe 'kubectl get deployments -o wide --show-labels'

p ""
p "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Change labels"
pe 'kubectl label deployments app1-test "canary=true"'

p  ""
p  "# Add annotation - usually longer than labels"
pe 'kubectl annotate deployments app1-test description="My favorite deployment with my app"'

p  ""
p  "# List 'canary' deployments (with canary label)"
pe 'kubectl get deployments -o wide --label-columns=canary'

p  ""
p  "# Remove label"
pe 'kubectl label deployments app1-test "canary-"'

p  ""
p  "# List pods including labels"
pe 'kubectl get pods --sort-by=.metadata.name --show-labels'

p  ""
p  "# List pods ver=2 using the --selector flag"
pe 'kubectl get pods --selector="ver=2" --show-labels'

p  ""
p  "# List pods with 2 tags"
pe 'kubectl get pods --selector="myapp=app2,ver=2" --show-labels'

p  ""
p  "# List pods where myapp=(app1 or app2)"
pe 'kubectl get pods --selector="myapp in (app1,app2)" --show-labels'

p  ""
p  "# Label multiple pods"
pe 'kubectl label pods -l canary=true my=testlabel'

p  ""
p  "# List all services"
pe 'kubectl get services -o wide'

p  ""
p  "# Get service details"
pe 'kubectl describe service app1-prod'

p  ""
p  "# Get service endpoints"
pe 'kubectl describe endpoints app1-prod'

p  ""
p  "# List IPs belongs to specific pods"
pe 'kubectl get pods -o wide --selector=myapp=app1,env=prod --show-labels'

p  ""
p  "# Cleanup all deployments"
pe 'kubectl delete services,deployments -l myapp'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Create/Scale ReplicaSet"
################################################


cat > files/kuard-rs.yaml << EOF
apiVersion: extensions/v1beta1
kind: ReplicaSet
metadata:
  name: kuard
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: kuard
        version: "2"
    spec:
      containers:
        - name: kuard
          image: "gcr.io/kuar-demo/kuard-amd64:2"
EOF

p  ""
p  "# Show minimal ReplicaSet definition"
pe 'cat files/kuard-rs.yaml'

p  ""
p  "# Create ReplicaSet"
pe 'kubectl apply -f files/kuard-rs.yaml'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Check pods"
pe 'kubectl get pods'

p  ""
p  "# Check ReplicaSet details"
pe 'kubectl describe rs kuard'

p  ""
p  "# The pods have the same labels as ReplicaSet"
pe 'kubectl get pods -l app=kuard,version=2 --show-labels'

p  ""
p  "# Check if pod is part of ReplicaSet"
pe 'kubectl get pods -l app=kuard,version=2 -o json | jq ".items[].metadata"'

p  ""
p  "# Scale up ReplicaSet"
pe 'kubectl scale replicasets kuard --replicas=4'

p  ""
p  "# New pods are beeing created"
pe 'kubectl get pods -l app=kuard --show-labels'

p  ""
p  "# Delete ReplicaSet"
pe 'kubectl delete rs kuard'


p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** DaemonSets + NodeSelector usage - run pods only on nodes with proper label"
################################################


p  ""
p  "# Add labels to your nodes (hosts)"
pe 'kubectl label nodes node2 ssd=true'

p  ""
p  "# Filter nodes based on labels"
pe 'kubectl get nodes --selector ssd=true'

cat > files/nginx-fast-storage.yaml << EOF
apiVersion: extensions/v1beta1
kind: "DaemonSet"
metadata:
  labels:
    app: nginx
    ssd: "true"
  name: nginx-fast-storage
spec:
  template:
    metadata:
      labels:
        app: nginx
        ssd: "true"
    spec:
      nodeSelector:
        ssd: "true"
      containers:
        - name: nginx
          image: nginx:1.10.0
EOF

p  ""
p  "# Check 'nginx-fast-storage.yaml' which will provision nginx to ssd labeled nodes only"
p  "# By default a DaemonSet will create a copy of a Pod on every node"
pe 'cat files/nginx-fast-storage.yaml'

p  ""
p  "# Create daemonset from the nginx-fast-storage.yaml"
pe 'kubectl apply -f files/nginx-fast-storage.yaml'

p  ""
p  "# Check the nodes where nginx was deployed"
pe 'kubectl get pods -o wide'

p  ""
p  "# Add label ssd=true to the node3 - nginx should be deployed there automatically"
pe 'kubectl label nodes node3 ssd=true'

p  ""
p  "# Check the nodes where nginx was deployed (it should be also on node3 with ssd=true label)"
pe 'kubectl get pods -o wide'

p  ""
p  "# Check the nodes where nginx was deployed"
pe 'kubectl delete ds nginx-fast-storage'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Batch jobs"
################################################


p  ""
p  "# One-shot Jobs provide a way to run a single Pod once until successful termination"
p  "# Pod is restarted in case of failure"
pe 'kubectl run -i oneshot --image=gcr.io/kuar-demo/kuard-amd64:1 --restart=OnFailure -- --keygen-enable --keygen-exit-on-complete --keygen-num-to-gen 5'

p  ""
p  "# List all jobs"
pe 'kubectl get jobs -o wide'

p  ""
p  "# Delete job"
pe 'kubectl delete jobs oneshot'

cat > files/job-oneshot.yaml << EOF
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

p  ""
p  "# Show one-shot Job configuration file"
pe 'cat files/job-oneshot.yaml'

p  ""
p  "# Create one-shot Job using a configuration file"
pe 'kubectl apply -f files/job-oneshot.yaml'
pe 'sleep 30'

p  ""
p  "# Print details about the job"
pe 'kubectl describe jobs oneshot'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Get pod name of a job called 'oneshot' and check the logs"
pe 'POD_NAME=$(kubectl get pods --selector="job-name=oneshot" -o=jsonpath="{.items[0].metadata.name}")'
pe 'kubectl logs ${POD_NAME}'

p  ""
p  "# Remove job oneshot"
pe 'kubectl delete jobs oneshot'

cat > files/job-oneshot-failure1.yaml << EOF
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

p  ""
p  "# Show one-shot Job configuration file"
p  "# See the keygen-exit-code parameter - nonzero exit code after generating three keys"
pe 'cat files/job-oneshot-failure1.yaml'

p  ""
p  "# Create one-shot Job using a configuration file"
pe 'kubectl apply -f files/job-oneshot-failure1.yaml'
pe 'sleep 60'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Get pod status - look for CrashLoopBackOff/Error indicating pod restarts"
pe 'kubectl get pod -l job-name=oneshot'

p  ""
p  "# Remove the job"
pe 'kubectl delete jobs oneshot'

cat > files/job-parallel.yaml << EOF
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

p  ""
p  "# Show Parallel Job configuration file - generate (5x10) keys generated in 5 containers"
pe 'cat files/job-parallel.yaml'

p  ""
p  "# Create Parallel Job using a configuration file"
pe 'kubectl apply -f files/job-parallel.yaml'

p  ""
p  "# Check the pods and list changes as they happen"
pe 'kubectl get pods --watch -o wide &'
pe 'sleep 10'
p  " "
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Stop getting the pods"
pe 'pkill -f "kubectl get pods --watch -o wide"'

p  ""
p  "# Remove the job"
pe 'kubectl delete jobs parallel'


p  ""
################################################
p  "*** Queue job example"
################################################


cat > /tmp/producer_queue_consumer-diagram.txt << EOF
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

p  ""
p  "# Memory-based work queue system: Producer -> Work Queue -> Consumers diagram"
pe 'cat /tmp/producer_queue_consumer-diagram.txt'

cat > files/rs-queue.yaml << EOF
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

p  ""
p  "# Create a simple ReplicaSet to manage a singleton work queue daemon"
pe 'cat files/rs-queue.yaml'

p  ""
p  "# Create work queue using a configuration file"
pe 'kubectl apply -f files/rs-queue.yaml'
pe 'sleep 30'

p  ""
p  "# Configure port forwarding to connect to the 'work queue daemon' pod"
pe 'QUEUE_POD=$(kubectl get pods -l app=work-queue,component=queue -o jsonpath="{.items[0].metadata.name}")'
pe 'kubectl port-forward $QUEUE_POD 8080:8080 &'
p  " "
p  "################################################################################################### Press <ENTER> to continue"
wait

cat > files/service-queue.yaml << EOF
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

p  ""
p  "# Expose work queue - this helps consumers+producers to locate the work queue via DNS"
pe 'cat files/rs-queue.yaml'

p  ""
p  "# Create the service pod using a configuration file"
pe 'kubectl apply -f files/service-queue.yaml'
pe 'sleep 20'

p  ""
p  "# Create a work queue called 'keygen'"
pe 'curl -X PUT 127.0.0.1:8080/memq/server/queues/keygen'

p  ""
p  "# Create work items and load up the queue"
pe 'for WORK in work-item-{0..20}; do curl -X POST 127.0.0.1:8080/memq/server/queues/keygen/enqueue -d "$WORK"; done'

p  ""
p  "# Queue should not be empty - check the queue by looking at the 'MemQ Server' tab in Web interface (http://127.0.0.1:8080/-/memq)"
pe 'curl --silent 127.0.0.1:8080/memq/server/stats | jq'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

cat > files/job-consumers.yaml << EOF
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

p  ""
p  "# Show consumer job config file allowing start up five pods in parallel"
p  "# Once the first pod exits with a zero exit code, the Job will not start any new pods (none of the workers should exit until the work is done)"
pe 'cat files/job-consumers.yaml'

p  ""
p  "# Create consumer job from config file"
pe 'kubectl apply -f files/job-consumers.yaml'
pe 'sleep 30'

p  ""
p  "# Five pods should be created to run until the work queue is empty"
p  "# Open the web browser to see changing queue status (http://127.0.0.1:8080/-/memq)"
pe 'kubectl get pods -o wide'

p  ""
p  "# Check the queue status - especially the 'dequeued' and 'depth' fields"
pe 'curl --silent 127.0.0.1:8080/memq/server/stats | jq'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Stop port-forwarding"
pe 'pkill -f "kubectl port-forward $QUEUE_POD 8080:8080"'

p  ""
p  "# Clear the resources"
pe 'kubectl delete rs,svc,job -l chapter=jobs'


p  ""
################################################
p  "*** ConfigMaps"
################################################


cat > files/my-config.txt << EOF
# This is a sample config file that I might use to configure an application
parameter1 = value1
parameter2 = value2
EOF

p  ""
p  "# Show file with key/value pairs which will be available to the pod"
pe 'cat files/my-config.txt'

p  ""
p  "# Create a ConfigMap with that file (environment variables are specified with a special valueFrom member)"
pe 'kubectl create configmap my-config --from-file=files/my-config.txt --from-literal=extra-param=extra-value --from-literal=another-param=another-value'

p  ""
p  "# Show ConfigMaps"
pe 'kubectl get configmaps'

p  ""
p  "# Show ConfigMap details"
pe 'kubectl describe configmap my-config'

p  ""
p  "# See the YAML ConfigMap object"
pe 'kubectl get configmaps my-config -o yaml'

cat > files/kuard-config.yaml << \EOF
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

p  ""
p  "# Prepare config file for ConfigMap usage"
pe 'cat files/kuard-config.yaml'

p  ""
p  "# Apply the config file"
pe 'kubectl apply -f files/kuard-config.yaml'
pe 'sleep 10'

p  ""
p  "# {EXTRA_PARAM,ANOTHER_PARAM} variable has value from configmap my-config/{extra-param,another-param} and file /config/my-config.txt exists in container"
pe 'kubectl exec kuard-config -- sh -xc "echo EXTRA_PARAM: \$EXTRA_PARAM; echo ANOTHER_PARAM: \$ANOTHER_PARAM && cat /config/my-config.txt"'

p  ""
p  "# Go to http://localhost:8080 and click on the 'Server Env' tab, then 'File system browser' tab (/config) and look for ANOTHER_PARAM and EXTRA_PARAM values"
pe 'kubectl port-forward kuard-config 8080:8080 &'
p  ' '
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Stop port forwarding"
p  'pkill -f "kubectl port-forward kuard-config 8080:8080"'

p  ""
p  "# Remove pod"
pe 'kubectl delete pod kuard-config'


p  ""
################################################
p  "*** Secrets"
################################################


p  ""
p  "# Download certificates"
pe 'wget -q -c -P files https://storage.googleapis.com/kuar-demo/kuard.crt https://storage.googleapis.com/kuar-demo/kuard.key'

p  ""
p  "# Create a secret named kuard-tls"
pe 'kubectl create secret generic kuard-tls --from-file=files/kuard.crt --from-file=files/kuard.key'

p  ""
p  "# Get details about created secret"
pe 'kubectl describe secrets kuard-tls'

p  ""
p  "# Show secrets"
pe 'kubectl get secrets'

p  ""
p  "# Update secrets - generate yaml and then edit the secret 'kubectl edit configmap my-config'"
pe 'kubectl create secret generic kuard-tls --from-file=files/kuard.crt --from-file=files/kuard.key --dry-run -o yaml | kubectl replace -f -'

cat > files/kuard-secret.yaml << EOF
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

p  ""
p  "# Create a new pod with secret attached"
pe 'cat files/kuard-secret.yaml'

p  ""
p  "# Apply the config file"
pe 'kubectl apply -f files/kuard-secret.yaml'
pe 'sleep 20'

p '# Set port-forwarding. Go to https://localhost:8080, check the certificate and click on "File system browser" tab (/tls)'
pe 'kubectl port-forward kuard-tls 8443:8443 &'
p  ' '
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Stop port forwarding"
pe 'pkill -f "kubectl port-forward kuard-tls 8443:8443"'

p  ""
p  "# Delete pod"
pe 'kubectl delete pod kuard-tls'


p  ""
################################################
p  "*** Deployments - create deployment, change docker image, rollback"
################################################


cat > files/nginx-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
EOF

p  ""
p  "# Show nginx deployment definition"
pe 'cat files/nginx-deployment.yaml'

p  ""
p  "# Create nginx deployment"
pe 'kubectl create -f files/nginx-deployment.yaml'

p  ""
p  "# List deployments"
pe 'kubectl get deployments -o wide'

p  ""
p  "# Get deployment details"
pe 'kubectl describe deployment nginx-deployment'

p  ""
p  "# Show deployment YAML file (look for: 'nginx:1.7.9')"
pe 'kubectl get deployment nginx-deployment -o wide'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Change deployment image (version 1.7.9 -> 1.8) - you can do the change by running 'kubectl edit deployment nginx-deployment' too..."
pe 'kubectl set image deployment nginx-deployment nginx=nginx:1.8'

p  ""
p  "# See what is happening during the deployment change"
pe 'kubectl rollout status deployment nginx-deployment'

p  ""
p  "# Get deployment details (see: 'nginx:1.8')"
pe 'kubectl get deployment nginx-deployment -o wide'

p  ""
p  "# Show details for deployment"
pe 'kubectl describe deployment nginx-deployment'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# See the deployment history (first there was version nginx:1.7.9, then nginx:1.8)"
pe 'kubectl rollout history deployment nginx-deployment --revision=1'
pe 'kubectl rollout history deployment nginx-deployment --revision=2'

p  ""
p  "# Rollback the deployment to previous version (1.7.9)"
pe 'kubectl rollout undo deployment nginx-deployment'
pe 'kubectl rollout status deployment nginx-deployment'

p  ""
p  "# Get deployment details - see the image is now again 'nginx:1.7.9'"
pe 'kubectl get deployment nginx-deployment -o wide'

p  ""
p  "# Rollback the deployment back to version (1.8)"
pe 'kubectl rollout undo deployment nginx-deployment --to-revision=2'
pe 'kubectl rollout status deployment nginx-deployment'

p  ""
p  "# Get deployment details - see the image is now again 'nginx:1.8'"
pe 'kubectl get deployment nginx-deployment -o wide'

p  ""
p  "# Check the utilization of pods"
pe 'kubectl top pod --heapster-namespace=myns --all-namespaces --containers'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Endpoints"
################################################


cat > files/dns-service.yaml << EOF
kind: Service
apiVersion: v1
metadata:
  name: external-database
spec:
  type: ExternalName
  externalName: database.company.com
EOF

p  ""
p  "# Show external service DNS definition"
pe 'cat files/dns-service.yaml'

p  ""
p  "# Create DNS name (CNAME) that points to the specific server running the database"
pe 'kubectl create -f files/dns-service.yaml'

p  ""
p  "# Show services"
pe 'kubectl get service'

p  ""
p  "# Remove service"
pe 'kubectl delete service external-database'


p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Self-Healing"
################################################


p  ""
p  "# Get pod details"
pe 'kubectl get pods -o wide'

p  ""
p  "# Get first nginx pod and delete it - one of the nginx pods should be in 'Terminating' status"
pe 'NGINX_POD=$(kubectl get pods -l app=nginx --output=jsonpath="{.items[0].metadata.name}")'
pe 'kubectl delete pod $NGINX_POD; kubectl get pods -l app=nginx -o wide'
pe 'sleep 10'

p  ""
p  "# Get pod details - one nginx pod should be freshly started"
pe 'kubectl get pods -l app=nginx -o wide'

p  ""
p  "# Get deployement details and check the events for recent changes"
pe 'kubectl describe deployment nginx-deployment'

p  ""
p  "# Halt one of the nodes (node2)"
pe 'vagrant halt node2'
pe 'sleep 30'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Get node details - node2 Status=NotReady"
pe 'kubectl get nodes'

p  ""
p  "# Get pod details - everything looks fine - you need to wait 5 minutes"
pe 'kubectl get pods -o wide'

p  ""
p  "# Pod will not be evicted until it is 5 minutes old -  (see Tolerations in 'describe pod' )"
p  "# It prevents Kubernetes to spin up the new containers when it is not necessary"
pe 'NGINX_POD=$(kubectl get pods -l app=nginx --output=jsonpath="{.items[0].metadata.name}")'
pe 'kubectl describe pod $NGINX_POD | grep -A1 Tolerations'

p  ""
p  "# Sleeping for 5 minutes"
pe 'sleep 300'

p  ""
p  "# Get pods details - Status=Unknown/NodeLost and new container was started"
pe 'kubectl get pods -o wide'

p  ""
p  "# Get depoyment details - again AVAILABLE=3/3"
pe 'kubectl get deployments -o wide'

p  ""
p  "# Power on the node2 node"
pe 'vagrant up node2'
pe 'sleep 70'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# Get node details - node2 should be Ready again"
pe 'kubectl get nodes'

p  ""
p  "# Get pods details - 'Unknown' pods were removed"
pe 'kubectl get pods -o wide'


p  ""
################################################
p  "*** Persistent Storage"
################################################


p  ""
p  "# Install and configure NFS on node1"
pe 'ssh $SSH_ARGS vagrant@node1 "sudo sh -xc \" apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y nfs-kernel-server > /dev/null; mkdir /nfs; chown nobody:nogroup /nfs; echo /nfs *\(rw,sync,no_subtree_check\) >> /etc/exports; systemctl restart nfs-kernel-server \""'

p  ""
p  "# Install NFS client to other nodes"
pe 'for COUNT in {2..4}; do ssh $SSH_ARGS vagrant@node${COUNT} "sudo sh -xc \"apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y nfs-common > /dev/null\""; done'

cat > files/nfs-volume.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
  labels:
    volume: nfs-volume
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 1Gi
  nfs:
    server: node1
    path: "/nfs"
EOF

p  ""
p  "# Show persistent volume object definition"
pe 'cat files/nfs-volume.yaml'

p  ""
p  "# Create persistent volume"
pe 'kubectl create -f files/nfs-volume.yaml'

p  ""
p  "# Check persistent volumes"
pe 'kubectl get persistentvolume'

cat > files/nfs-volume-claim.yaml << EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfs-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  selector:
    matchLabels:
      volume: nfs-volume
EOF

p  ""
p  "# Show persistent volume claim object definition"
pe 'cat files/nfs-volume-claim.yaml'

p  ""
p  "# Claim the persistent volume for our pod"
pe 'kubectl create -f files/nfs-volume-claim.yaml'

p  ""
p  "# Check persistent volume claims"
pe 'kubectl get persistentvolumeclaim'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

cat > files/nfs-test-replicaset.yaml << EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nfs-test
  # labels so that we can bind a service to this pod
  labels:
    app: nfs-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nfs-test
  template:
    metadata:
      labels:
        app: nfs-test
    spec:
      containers:
      - name: nfs-test
        image: busybox
        command: [ 'sh', '-c', 'date >> /tmp/date && sleep 3600' ]
        volumeMounts:
          - name: nfs-test
            mountPath: "/tmp"
      volumes:
      - name: nfs-test
        persistentVolumeClaim:
          claimName: nfs-pvc
      securityContext:
        runAsUser: 65534
        fsGroup: 65534
EOF

p  ""
p  "# Show replicaset definition"
pe 'cat files/nfs-test-replicaset.yaml'

p  ""
p  "# Create replicaset"
pe 'kubectl create -f files/nfs-test-replicaset.yaml'
pe 'sleep 20'

p  ""
p  "# You can see the /tmp is mounted to both pods containing the same file 'date'"
pe 'NFS_TEST_POD2=$(kubectl get pods --no-headers -l app=nfs-test -o custom-columns=NAME:.metadata.name | head -1); echo $NFS_TEST_POD2'
pe 'NFS_TEST_POD1=$(kubectl get pods --no-headers -l app=nfs-test -o custom-columns=NAME:.metadata.name | tail -1); echo $NFS_TEST_POD1'
pe 'kubectl exec -it $NFS_TEST_POD1 -- sh -xc "hostname; echo $NFS_TEST_POD1 >> /tmp/date"'
pe 'kubectl exec -it $NFS_TEST_POD2 -- sh -xc "hostname; echo $NFS_TEST_POD2 >> /tmp/date"'

p  ""
p  "# Show files on NFS server - there should be 'nfs/date' file with 2 dates"
pe 'ssh $SSH_ARGS vagrant@node1 "set -x; ls -al /nfs -ls; ls -n /nfs; cat /nfs/date"'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Node replacement"
################################################


p  ""
p  "# Move all pods away from node3"
pe 'kubectl drain --delete-local-data --ignore-daemonsets node3'

p  ""
p  "# Get pod details"
pe 'kubectl get pods -o wide --all-namespaces | grep node3'

p  ""
p  "# Destroy the node node3"
pe 'vagrant destroy -f node3'

p  ""
p  "# Wait some time for Kubernetes to catch up..."
pe 'sleep 40'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait

p  ""
p  "# The node3 shoult be in 'NotReady' state"
pe 'kubectl get pods -o wide --all-namespaces'

p  ""
p  "# Remove the node3 from the cluster"
pe 'kubectl delete node node3'

p  ""
p  "# Generate command which can add new node to Kubernetes cluster"
pe 'KUBERNETES_JOIN_CMD=$(ssh $SSH_ARGS root@node1 "kubeadm token create --print-join-command"); echo $KUBERNETES_JOIN_CMD'

p  ""
p  "# Start new node"
pe 'vagrant up node3'

p  ""
p  "# Install Kubernetes repository to new node"
pe 'ssh $SSH_ARGS vagrant@node3 "sudo sh -xc \" apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https curl > /dev/null; curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -; echo deb https://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list \""'

p  ""
p  "# Install Kubernetes packages"
pe 'ssh $SSH_ARGS vagrant@node3 "sudo sh -xc \" apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io kubelet=${KUBERNETES_VERSION}-00 kubeadm=${KUBERNETES_VERSION}-00 kubectl=${KUBERNETES_VERSION}-00 > /dev/null \""'

p  ""
p  "# Join node3 to the Kuberenets cluster"
pe 'ssh $SSH_ARGS vagrant@node3 "sudo sh -xc \" $KUBERNETES_JOIN_CMD \""'
pe 'sleep 40'

p  ""
p  "# Check the nodes - node3 should be there"
pe 'kubectl get nodes'

p  ""
p  "################################################################################################### Press <ENTER> to continue"
wait


p  ""
################################################
p  "*** Notes"
################################################


p  ""
p  "# Show logs from specific docker container inside pod"
pe 'kubectl logs --namespace=kube-system $(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name) --container=dnsmasq --tail=10'
pe 'kubectl logs --namespace=kube-system $(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name) --container=kubedns --tail=10'

p  ""
p  "# See the logs directly on the Kubernetes node"
pe 'ssh $SSH_ARGS vagrant@node1 "ls /var/log/containers/"'

p  ""
p  "# Show all"
pe 'kubectl get all'


#pe 'kubectl delete namespace myns'
#p ""
