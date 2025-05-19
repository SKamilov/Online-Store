output "kubeconfig_cmd" {
  value = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.momo_cluster.id} --external --force"
}