#!/bin/bash

# Setup variables
group=aks-lab
region=westeurope

# Local variables
NODE_COUNT=3

# Create resource group
echo '[STEP 1] Creating resource group '$group 'in region '$region
az group create -n $group -l $region

# Get latest version of k8s for your region
version=$(az aks get-versions -l "$region" --query 'orchestrators[-1].orchestratorVersion' -o tsv)

# Create AKS cluster on your subscription, without using service principal and with autoscaler
echo '[STEP 2] Spinning up AKS cluster aks-cluster in group '$group' in region '$region' using '$version' of kubernetes'
az aks create -g $group -n aks-cluster -l $region \
    --node-count $NODE_COUNT \
    --node-vm-size Standard_DS2_v2 \
    --generate-ssh-keys \
    --vm-set-type VirtualMachineScaleSets \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --tags 'can-delete=yes' 'owner=piotrzan' \
    --kubernetes-version "$version" --verbose

# Set cluster in kubeconfig
echo '[STEP 3] Setting up connection to cluster for Azure Shell'
az aks get-credentials -g $group -n aks-cluster --overwrite-existing

# Get some aliases
echo '[STEP 4] Creating useful aliases'

# Instead of typing kubectl all the time, abbreviate it to just “k”
alias k=kubectl

# Check what is running on the cluster
alias kdump='kubectl get all --all-namespaces'

# Display helpful info for creating k8s resources imperatively
alias krun='k run -h | grep "# " -A2'

# Quickly spin up busybox pod for diagnostic purposes
alias kdiag='kubectl run -it --rm debug --image=busybox --restart=Never -- sh'

echo '[STEP 5] Setup auto-completion'

source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

complete -F __start_kubectl k
echo 'complete -F __start_kubectl k' >> ~/.bashrc