set -o xtrace

# CLUSTER CONFIGURATION

CLUSTER_NAME="${cluster_name}"
API_SERVER_ENDPOINT="${cluster_endpoint}"
B64_CLUSTER_CA="${cluster_ca}"

# Amazon Linux 2 EKS-optimized AMI has this pre-installed
# This ensures it's available
if [ ! -f /etc/eks/bootstrap.sh ]; then
  echo "Installing EKS bootstrap utilities..."
  yum install -y amazon-ssm-agent
fi

# --apiserver-endpoint: EKS API endpoint
# --b64-cluster-ca: Cluster CA for TLS verification
# --kubelet-extra-args: Additional kubelet configuration
/etc/eks/bootstrap.sh $${CLUSTER_NAME} \
  --apiserver-endpoint $${API_SERVER_ENDPOINT} \
  --b64-cluster-ca $${B64_CLUSTER_CA} \
  --kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=normal'
  