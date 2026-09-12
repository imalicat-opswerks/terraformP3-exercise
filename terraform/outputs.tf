output "instance_ip" {
  description = "Public IP address of the app instance."
  value       = tolist(linode_instance.app.ipv4)[0]
}

output "instance_label" {
  value = linode_instance.app.label
}

output "database_label" {
  value = linode_database_mysql_v2.db.label
}

output "database_host" {
  value = linode_database_mysql_v2.db.host_primary
}

output "object_storage_folder" {
  description = "Folder under the shared bucket holding this engineer's site content."
  value       = "${var.engineer_slug}/site/"
}

output "object_storage_access_key" {
  value     = linode_object_storage_key.app.access_key
  sensitive = true
}
