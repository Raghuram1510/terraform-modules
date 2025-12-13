#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF

yum install -y kubelet kubeadm kubectl
systemctl enable kubelet
swapoff -a

echo "${node_type} node ready"