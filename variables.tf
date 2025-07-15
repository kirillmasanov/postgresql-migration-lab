variable "cloud_id" {
  description = "Yandex Cloud Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud Zone"
  type        = string
}

variable "vm_user" {
  description = "SSH username for VM"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "pg_user" {
  description = "PostgreSQL user"
  type        = string
}

variable "pg_password" {
  description = "Password for PostgreSQL user"
  type        = string
  sensitive   = true
}

variable "pg_database" {
  description = "PostgreSQL DB name"
  type        = string
  default     = "migration_db"
}