# Multinode Kubernetes Cluster

![Kubernetes Logo](https://s28.postimg.org/lf3q4ocpp/k8s.png)

Few scripts which may help you to quickly build Multinode Kubernetes cluster.
By running the scripts you got access to 4 node cluster running on VMs.

* [run-kubeadm.sh](run-kubeadm.sh) - is using standard "kubernetes tool" [kubeadm](https://github.com/kubernetes/kubeadm) for [creating the cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
* [run-kubespray.sh](run-kubespray.sh) - script is using [Kubespray](https://github.com/kubernetes-incubator/kubespray) to build enterprise ready cluster

## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt)
* [Vagrant Host Manager Plugin](https://github.com/devopsgroup-io/vagrant-hostmanager)

Packages (+dependencies):
* git
* kubectl
* qemu-system-x86
* qemu-utils
* vagrant
* [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)
* [vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager)

## Login Credentials

* Username: root / vagrant
* Password: vagrant

## Usage

Make sure your system meet all requirements.
For Ubuntu Xenial (16.04) you can see the installation details here: [.appveyor.yml](.appveyor.yml)

Simply run one of the commands `run-kubeadm.sh` or `run-kubespray.sh` and wait for few minutes.

You can see the example of such executions here:

* `run-kubeadm.sh`
[![asciicast](https://asciinema.org/a/174963.png)](https://asciinema.org/a/174963)

* `run-kubespray.sh`
[![asciicast](https://asciinema.org/a/174965.png)](https://asciinema.org/a/174965)

Once you installed the cluster use these commands to test your connection:

```
export KUBECONFIG=$PWD/kubeconfig.conf

kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

## License

MIT / BSD

## Author Information

Scripts were created in 2018 by <petr.ruzicka@gmail.com>
