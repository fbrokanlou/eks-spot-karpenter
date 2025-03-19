output "rendered_karpenter_node_class" {
  value = yamlencode(kubernetes_manifest.karpenter_node_class.manifest)
}
