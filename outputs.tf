output "source_db_ssh_command" {
  description = "SSH command to connect to source database VM"
  value       = "ssh ${var.vm_user}@${yandex_compute_instance.source_db.network_interface.0.nat_ip_address}"
}

