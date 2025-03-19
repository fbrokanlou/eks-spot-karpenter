
# https://karpenter.sh/docs/concepts/nodeclasses/
resource "kubernetes_manifest" "karpenter_node_class" {
  manifest = yamldecode(<<-EOT
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiSelectorTerms:
    - alias: bottlerocket@latest
  role: "${module.karpenter.node_iam_role_name}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${module.eks.cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${module.eks.cluster_name}"
  tags:
    karpenter.sh/discovery: "${module.eks.cluster_name}"
EOT
  )
  depends_on = [
    helm_release.karpenter
  ]
}

# https://karpenter.sh/docs/concepts/nodepools/
resource "kubernetes_manifest" "karpenter_node_pool" {
  manifest = yamldecode(<<-EOT
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
  limits:
    cpu: 32
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
EOT
  )
  depends_on = [
    kubernetes_manifest.karpenter_node_class
  ]
}