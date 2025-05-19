################################################################################
#  tf-admin — сервис-аккаунт, под которым работает Terraform
################################################################################
data "yandex_iam_service_account" "tf_admin" {
  name = "tf-admin"
}

# tf-admin – агент управляемых кластеров
resource "yandex_resourcemanager_folder_iam_member" "tf_admin_clusters_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${data.yandex_iam_service_account.tf_admin.id}"
}

# tf-admin – полный доступ к Cluster API и туннелям
resource "yandex_resourcemanager_folder_iam_member" "tf_admin_cluster_api" {
  folder_id = var.yc_folder_id
  role      = "k8s.cluster-api.cluster-admin"
  member    = "serviceAccount:${data.yandex_iam_service_account.tf_admin.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "tf_admin_tunnel_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.tunnelClusters.agent"
  member    = "serviceAccount:${data.yandex_iam_service_account.tf_admin.id}"
}

# минимально-необходимое: генерировать токены любых SA
resource "yandex_resourcemanager_folder_iam_binding" "tf_admin_sa_user" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.user"
  members   = ["serviceAccount:${data.yandex_iam_service_account.tf_admin.id}"]
}

# полные права внутри каталога (не перезаписывает другие биндинги)
resource "yandex_resourcemanager_folder_iam_member" "tf_admin_admin" {
  folder_id = var.yc_folder_id
  role      = "admin"
  member    = "serviceAccount:${data.yandex_iam_service_account.tf_admin.id}"
}

################################################################################
#  Кластер Kubernetes
################################################################################
resource "yandex_kubernetes_cluster" "momo_cluster" {
  name       = "momo-cluster"
  network_id = yandex_vpc_network.momo_net.id

  master {
    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.momo_subnet.id
    }
    public_ip = true
  }

  network_policy_provider = "CALICO"

  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.node_sa.id
}

################################################################################
#  Сервис-аккаунты кластера
################################################################################
resource "yandex_iam_service_account" "k8s_sa" {
  name = "k8s-master-sa"
}

resource "yandex_iam_service_account" "node_sa" {
  name = "k8s-node-sa"
}

# базовая роль для мастера
resource "yandex_resourcemanager_folder_iam_binding" "k8s_sa_admin" {
  folder_id = var.yc_folder_id
  role      = "k8s.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

# мастеру нужны дополнительные возможности
resource "yandex_resourcemanager_folder_iam_binding" "k8s_master_sa_token" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.tokenCreator"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s_master_sa_lb" {
  folder_id = var.yc_folder_id
  role      = "load-balancer.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s_master_sa_vpc" {
  folder_id = var.yc_folder_id
  role      = "vpc.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s_master_sa_registry" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

# мастер‑SA может генерировать short‑lived IAM‑токены для node‑SA
resource "yandex_resourcemanager_folder_iam_binding" "k8s_master_sa_sa_user" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.user"
  members   = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

# права для нодового SA
resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_vpc" {
  folder_id = var.yc_folder_id
  role      = "vpc.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}


resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_registry" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

# разрешаем node‑SA использовать образы ВМ
resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_compute_images" {
  folder_id = var.yc_folder_id
  role      = "compute.images.user"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}


resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_admin" {
  folder_id = var.yc_folder_id
  role      = "k8s.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

# --- дополнительные права node‑SA (как у tf-admin) ---
resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_clusters_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.node_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_cluster_api" {
  folder_id = var.yc_folder_id
  role      = "k8s.cluster-api.cluster-admin"
  member    = "serviceAccount:${yandex_iam_service_account.node_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_tunnel_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.tunnelClusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.node_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_admin" {
  folder_id = var.yc_folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.node_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_sa_user" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.user"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

# облачный editor, чтобы node‑SA имел те же возможности, что и tf-admin
resource "yandex_resourcemanager_cloud_iam_binding" "k8s_node_sa_editor_cloud" {
  cloud_id = var.yc_cloud_id
  role     = "editor"
  members  = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

# cloud‑level VPC permissions for SA
resource "yandex_resourcemanager_cloud_iam_binding" "k8s_master_sa_vpc_cloud" {
  cloud_id = var.yc_cloud_id
  role     = "vpc.admin"
  members  = ["serviceAccount:${yandex_iam_service_account.k8s_sa.id}"]
}

resource "yandex_resourcemanager_cloud_iam_binding" "k8s_node_sa_vpc_cloud" {
  cloud_id = var.yc_cloud_id
  role     = "vpc.admin"
  members  = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

################################################################################
#  Node Group
################################################################################
resource "yandex_kubernetes_node_group" "momo_nodes" {
  cluster_id = yandex_kubernetes_cluster.momo_cluster.id
  name       = "momo-nodes"

  instance_template {
    platform_id = "standard-v1"
    resources {
      cores  = 2
      memory = 4
    }
    boot_disk {
      size = 50
      type = "network-ssd"
    }
  }

  scale_policy {
    fixed_scale { size = 2 }
  }
}

resource "yandex_resourcemanager_cloud_iam_binding" "tf_admin_editor_cloud" {
  cloud_id = var.yc_cloud_id
  role     = "editor"
  members  = ["serviceAccount:${data.yandex_iam_service_account.tf_admin.id}"]
}

###############################################################################
# дополнительные вычислительные права для k8s-node-sa
###############################################################################

###############################################################################
#  k8s-node-sa: ещё две роли, которых не хватает
###############################################################################
# (1) выдача/обновление short-lived oauth токенов для kubelet/kube-proxy
resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_token" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.tokenCreator"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}


# (2) работа с внешними балансировщиками (service Type = LoadBalancer)
resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_lb" {
  folder_id = var.yc_folder_id
  role      = "load-balancer.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

###############################################################################
# k8s-node-sa: полный доступ к Compute (аналогично tf-admin)
###############################################################################
resource "yandex_resourcemanager_folder_iam_binding" "k8s_node_sa_compute_admin" {
  folder_id = var.yc_folder_id
  role      = "compute.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.node_sa.id}"]
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.node_sa.id}"
}

# Node SA — admin на папке (folder)
resource "yandex_resourcemanager_folder_iam_member" "k8s_node_sa_full_admin" {
  folder_id = var.yc_folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.node_sa.id}"
}
