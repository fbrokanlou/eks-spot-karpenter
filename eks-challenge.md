# Senior Platform Engineer - AWS EKS Technical Challenge

## Objective
This challenge is designed to evaluate your ability to quickly learn and apply new tooling and approaches that may be unfamiliar to you.

Your task is to build an AWS EKS cluster using Terraform with the following specifications:
- Bottlerocket OS as the node operating system
- EC2 Spot Instances for worker nodes
- Karpenter for auto-scaling

We understand that some or all of these technologies might be new to you, and that's intentional. The tooling and approaches in this challenge are intended for an AWS-centric Kubernetes environment. We're interested in seeing your approach to learning these AWS-specific tools, how you navigate documentation, and how you implement a working solution within time constraints.

## Deliverables

1. Terraform configuration files for the infrastructure
2. A README explaining your approach and any interesting discoveries
3. Brief notes on challenges faced (if any)

All deliverables should be submitted in a Git repository.

## Requirements

### EKS Cluster
- Deploy an EKS cluster using AWS EKS module for Terraform
- Configure node groups using Bottlerocket OS AMI
- Implement Spot Instances for worker nodes

### Auto-scaling with Karpenter
- Install Karpenter in the cluster
- Set up a basic Karpenter provisioner for Spot Instance management
- Configure a simple node template using Bottlerocket OS

### Documentation
- Briefly document your approach and key decisions
- Share any interesting learnings from the process

## Optional Components (For Fun)
- Deploy any sample workload to test your cluster
- Experiment with additional Karpenter features if time permits

This challenge is designed to be exploratory and educational. We're more interested in seeing your approach than perfect implementation. Feel free to keep things simple where appropriate, and don't worry about creating a production-grade solution in this limited time frame. Have fun with it!
