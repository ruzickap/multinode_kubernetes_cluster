# Multinode Kubernetes Cluster

![Kubernetes Logo](https://s28.postimg.org/lf3q4ocpp/k8s.png)

Few scripts which may help you to quickly build Multinode Kubernetes cluster.
By running the scripts you got access to 4 node cluster.

* [run-kubeadm.sh](run-kubeadm.sh) - is using standard "kubernetes tool" [kubeadm](https://github.com/kubernetes/kubeadm) for [creating the cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
* [run-kubespray.sh](run-kubespray.sh) - script is using [Kubespray](https://github.com/kubernetes-incubator/kubespray) to build enterprise ready cluster

## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)

Packages (+dependencies):
* git
* kubectl
* qemu-system-x86
* qemu-utils
* vagrant-libvirt

## Login Credentials

* Username: root / vagrant
* Password: vagrant

## Usage

Simply run one of the commands and wait for few minutes.

You can see the example of such execution here:

Use these commands to test your connection to the cluster:

```
test -f $PWD/kubespray/inventory/mycluster/artifacts/admin.conf && export KUBECONFIG=$PWD/kubespray/inventory/mycluster/artifacts/admin.conf
test -f $PWD/config && export KUBECONFIG=$PWD/config

kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

## License

MIT / BSD

## Author Information

Scripts were created in 2018 by <petr.ruzicka@gmail.com>
