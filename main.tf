# ============ Network setup ============

resource "yandex_vpc_network" "migration_network" {
  name = "migration-network"
}

resource "yandex_vpc_subnet" "migration_subnet" {
  name           = "migration-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.migration_network.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_vpc_security_group" "vm_sg" {
  name       = "vm-security-group"
  network_id = yandex_vpc_network.migration_network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = [yandex_vpc_subnet.migration_subnet.v4_cidr_blocks[0]]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "managed_pg_sg" {
  name       = "managed-pg-security-group"
  network_id = yandex_vpc_network.migration_network.id

  ingress {
    protocol       = "TCP"
    port           = 6432
    v4_cidr_blocks = [yandex_vpc_subnet.migration_subnet.v4_cidr_blocks[0]]
  }
}

# ============ VM for PostreSQL setup ============

resource "yandex_iam_service_account" "vm_sa" {
  name        = "vm-service-account"
  description = "Service account for VM"
}

resource "yandex_resourcemanager_folder_iam_binding" "vm_sa_editor" {
  folder_id = var.folder_id
  role      = "compute.editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.vm_sa.id}",
  ]
}

resource "yandex_compute_instance" "source_db" {
  name        = "source-db-vm"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jfh73rvks3qlqp3ck" # Ubuntu 24.04
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.migration_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.vm_sg.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/metadata.yaml.tftpl", {
      user    = var.vm_user
      pubkey  = var.ssh_public_key
      pg_user = var.pg_user
      pg_pass = var.pg_password
      pg_db   = var.pg_database
      pg_subnet = yandex_vpc_subnet.migration_subnet.v4_cidr_blocks[0]
    })
  }
}

# ============ Managed PostreSQL cluster setup ============

resource "yandex_mdb_postgresql_cluster" "target_db" {
  name               = "target-db-cluster"
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.migration_network.id
  security_group_ids = [yandex_vpc_security_group.managed_pg_sg.id]

  config {
    version = 16
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 20
    }

    access {
      web_sql       = true
      data_transfer = true
    }

    postgresql_config = {
      max_connections                   = 100
      enable_parallel_hash              = true
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
    }
  }

  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.migration_subnet.id
  }
}

resource "yandex_mdb_postgresql_user" "admin_user" {
  cluster_id = yandex_mdb_postgresql_cluster.target_db.id
  name       = var.pg_user
  password   = var.pg_password
}

resource "yandex_mdb_postgresql_database" "migration_db" {
  cluster_id = yandex_mdb_postgresql_cluster.target_db.id
  name       = var.pg_database
  owner      = yandex_mdb_postgresql_user.admin_user.name
  depends_on = [yandex_mdb_postgresql_user.admin_user]
}
