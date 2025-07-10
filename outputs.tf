# output "source_db_public_ip" {
#   description = "Public IP address of the source database VM"
#   value       = yandex_compute_instance.source_db.network_interface.0.nat_ip_address
# }

output "source_db_ssh_command" {
  description = "SSH command to connect to source database VM"
  value       = "ssh ${var.vm_user}@${yandex_compute_instance.source_db.network_interface.0.nat_ip_address}"
}

# output "target_db_host" {
#   description = "Hostname of the target Managed PostgreSQL cluster"
#   value       = yandex_mdb_postgresql_cluster.target_db.host[0].fqdn
# }

# output "target_db_port" {
#   description = "Port of the target Managed PostgreSQL cluster"
#   value       = yandex_mdb_postgresql_cluster.target_db.host[0]
# }

# output "target_db_connection_string" {
#   description = "Connection string for target database"
#   value       = "postgresql://admin:${var.pg_password}@${yandex_mdb_postgresql_cluster.target_db.host[0].fqdn}:6432/migration_db"
#   sensitive   = true
# }