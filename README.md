# AWS EKS (Bottlerocket OS + SPOT Nodes) and Karpenter setup via Terraform

This repository contains Terraform configurations to deploy an Amazon Elastic Kubernetes Service (EKS) cluster integrated with Karpenter for efficient Kubernetes node provisioning.

I have used Terraform modules for EKS, VPC, and Karpenter, such as `terraform-aws-modules/eks` and `terraform-aws-modules/vpc`. This modular approach promotes reusability, simplifies configuration, and aligns with Terraform best practices. It also helped me to focus on high-level configurations while delegating resource creation to well-tested modules.

Although the task required SPOT worker nodes, I have created an On-Demand managed node group to host Kubernetes key addons (e.g., CoreDNS, kube-proxy) and Karpenter itself, ensuring that critical Kubernetes components and Karpenter remain operational even during Spot Instance interruptions.

I utilized the `helm_release` resource to deploy Karpenter, streamlining the process and enabling easy configuration. This approach offers extensive customization through values, making it adaptable to various environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Repository Structure](#repository-structure)
3. [Setup Instructions](#setup-instructions)
    - [1. Initialize and provision the resources by Terraform](#1-initialize-and-provision-the-resources-by-terraform)
    - [2. Configure kubectl](#2-configure-kubectl)
    - [3. Ensure your AWS Account has the necessary Service-Linked Role for Spot instance provisioning](#3-ensure-your-aws-account-has-the-necessary-service-linked-role-for-spot-instance-provisioning)
    - [4. Deploy and Test Auto-Scaling by Adjusting Replica Count](#4-deploy-and-test-auto-scaling-by-adjusting-replica-count)
4. [Issues I faced during implementation](#issues-i-faced-during-implementation)
    - [1. Insufficient CPU for Daemonset and Workload](#1-insufficient-cpu-for-daemonset-and-workload)
    - [2. Spot Instance Provisioning Failure](#2-spot-instance-provisioning-failure)
    - [3. Workloads Scheduled on Managed Node Group](#3-workloads-scheduled-on-managed-node-group)
    - [4. Pending Workloads After Scale-Up](#4-pending-workloads-after-scale-up)
5. [Cleanup](#cleanup)
6. [References](#references)
7. [My Considerations on running Karpenter in a production environment](#my-considerations-on-running-karpenter-in-a-production-environment)
    - [1. Define NodePools and Instance Types Carefully](#1-define-nodepools-and-instance-types-carefully)
    - [2. Use Affinity, Anti-Affinity & Taints/Tolerations](#2-use-affinity-anti-affinity--taintstolerations)
    - [3. Configure Karpenter for Multi-AZ & Fallback](#3-configure-karpenter-for-multi-az--fallback)
    - [4. Manage Spot Interruption Handling](#4-manage-spot-interruption-handling)
    - [5. Optimize Auto-Scaling Policies and use Consolidation](#5-optimize-auto-scaling-policies-and-use-consolidation)

## Prerequisites

1. **Terraform**: Install [Terraform](https://www.terraform.io/downloads.html).
2. **AWS CLI**: Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
3. **kubectl**: Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
4. **IAM Permissions**: Ensure your AWS credentials have sufficient permissions to create EKS clusters, IAM roles, and EC2 instances.

## Repository Structure

```plaintext
.
├── eks.tf                # EKS cluster configuration
├── karpenter.tf          # Karpenter setup
├── karpenter-nodes.tf    # Karpenter `EC2NodeClass` and `NodePool` resource definition
├── main.tf               # Main Terraform entry point (Providers and Data sources)
├── outputs.tf            # Outputs for Terraform resources
├── variables.tf          # Input variables for the Terraform configuration
├── vpc.tf                # VPC configuration for the EKS cluster
├── terraform.tfvars      # Variable values
├── deployment.yaml       # Example Kubernetes deployment to test auto-scaling
└── README.md             # Documentation
```

## Setup Instructions

### 1. Initialize and provision the resources by Terraform
Run the following command to initialize and deploy the infrastructure:
```sh
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl
Update your kubeconfig to interact with the EKS cluster:
```sh
aws eks --region <region> update-kubeconfig --name <cluster-name>
```

Replace `<region>` with your AWS region and `<cluster-name>` with your EKS cluster name. These values should match the ones defined in your `terraform.tfvars` file. For example:
```sh
aws eks --region us-east-1 update-kubeconfig --name karpenter
```

### 3. Ensure your AWS Account has the necessary Service-Linked Role for Spot instance provisioning

Before provisioning Spot Instances, verify that your AWS account has the required service-linked role configured. If not, create it using the following command:
```sh
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

### 4. Deploy and Test Auto-Scaling by Adjusting Replica Count

Deploy the example Kubernetes deployment provided in `deployment.yaml`:
```sh
kubectl apply -f deployment.yaml
```

Modify the `replica_count` of the deployment to observe node scale-up and scale-down behavior. For example, update the replicas to a higher value to trigger scale-up:
```sh
kubectl scale deployment <deployment-name> --replicas=<desired-replica-count>
```


## Issues I faced during implementation:

> **Note:**  Watch Karpenter's controller logs with:
`kubectl logs -f -n kube-system -l app.kubernetes.io/name=karpenter -c controller`

### 1. Insufficient CPU for Daemonset and Workload
**Error**:
```sh
could not schedule pod ... no instance type satisfied resources ...
```
**Solution**: CPU resource limit was too low. I updated the Karpenter `nodepool` resource to allow instance types with at least 4 CPU cores.

---

### 2. Spot Instance Provisioning Failure
**Error**:
```sh
The provided credentials do not have permission to create the service-linked role for EC2 Spot Instances.
```
**Solution**: Created the required service-linked role:
```sh
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

---

### 3. Workloads Scheduled on Managed Node Group
**Issue**: Workloads are scheduled on the main managed node group instead of Karpenter nodes.
**Solution**: Used node taints to ensure pods that do not tolerate the taint are scheduled on Karpenter nodes:
```yaml
      taints = {
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        },
      }
```

---

### 4. Pending Workloads After Scale-Up
**Error**:
```sh
could not schedule pod ... all available instance types exceed limits for nodepool ...
```
**Solution**: Increased the CPU limit in Karpenter's `nodepool` resource.


## Cleanup

To destroy the infrastructure, run:
```sh
terraform destroy
```

## References

- [Karpenter Documentation](https://karpenter.sh/docs/)
- [Karpenter example by Terraform](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/karpenter)


## My Considerations on running Karpenter in a production environment
I believe these are the key factors should be considered to ensure proper workload distribution and efficient node provisioning to optimize cost, performance, and availability:

### 1. Define NodePools and Instance Types Carefully
- Use multiple instance types to ensure availability and cost efficiency.
- Avoid single instance-type dependency to prevent failures due to spot interruptions.

Example NodePool configuration:
```yaml
    spec:
    requirements:
        - key: node.kubernetes.io/instance-type
        operator: In
        values: ["m5.large", "m5a.large", "m5n.large", "m5d.large"]
```

### 2. Use Affinity, Anti-Affinity & Taints/Tolerations
Ensure workloads are properly distributed across nodes using:
- **Node Affinity:** Schedule workloads on nodes with specific labels.
- **Pod Anti-Affinity:** Avoid scheduling all pods on the same node.
- **Taints and Tolerations:** Prevent workloads from running on specific node groups.

### 3. Configure Karpenter for Multi-AZ & Fallback
Use multiple availability zones (AZs) to increase resilience.
```yaml
spec:
  requirements:
    - key: topology.kubernetes.io/zone
      operator: In
      values: ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### 4. Manage Spot Interruption Handling
https://karpenter.sh/docs/concepts/disruption/

Spot instances can be interrupted, so implement:

- Pod Disruption Budgets (PDBs) to prevent mass pod evictions.
- Graceful shutdown hooks for cleanup before termination.
- Multiple instance types to avoid interruption risks.

### 5. Optimize Auto-Scaling Policies and use Consolidation
- Set minimum and maximum node constraints.
- Optimize for cost & latency by balancing Karpenter's bin-packing efficiency.
- Use Consolidation for Cost Efficiency. Enabled by default, but should be fine-tuned based on workload sensitivity.
