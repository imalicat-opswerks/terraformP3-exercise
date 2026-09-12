locals {
  name_prefix = "a3-tfp3-${var.engineer_slug}"
}

resource "linode_instance" "app" {
  label           = "${local.name_prefix}-app"
  region          = var.region
  type            = var.instance_type
  image           = var.instance_image
  authorized_keys = [var.ssh_public_key]
  tags            = ["tfp3", var.engineer_slug]

  # No root_pass: SSH key auth only (spec requires no root password).
  stackscript_id = linode_stackscript.bootstrap.id
  stackscript_data = {
    DB_HOST        = linode_database_mysql_v2.db.host_primary
    DB_PORT        = tostring(linode_database_mysql_v2.db.port)
    DB_USER        = linode_database_mysql_v2.db.root_username
    DB_PASSWORD    = linode_database_mysql_v2.db.root_password
    DB_NAME        = var.db_name
    OBJ_ACCESS_KEY = linode_object_storage_key.app.access_key
    OBJ_SECRET_KEY = linode_object_storage_key.app.secret_key
    OBJ_BUCKET     = var.shared_bucket_label
    OBJ_REGION     = var.shared_bucket_region
    ENGINEER_SLUG  = var.engineer_slug
    TFAPP_USER     = var.tfapp_user
  }
}

resource "linode_firewall_device" "app" {
  firewall_id = var.shared_firewall_id
  entity_id   = linode_instance.app.id
  entity_type = "linode"
}

resource "linode_database_mysql_v2" "db" {
  label        = "${local.name_prefix}-db"
  engine_id    = var.db_engine
  region       = var.region
  type         = var.db_type
  cluster_size = var.db_cluster_size

  # allow_list can't reference linode_instance.app.ip_address: that would
  # create a dependency cycle (the instance needs DB credentials at boot).
  # ssl_connection/encrypted are read-only here, not settable.
  allow_list = var.db_allow_list
}

resource "linode_object_storage_key" "app" {
  label = "${local.name_prefix}-key"

  bucket_access {
    bucket_name = var.shared_bucket_label
    # Plain region ("ap-south"), not the cluster/endpoint id ("ap-south-1")
    # used elsewhere for this bucket -- different fields, different formats.
    region      = replace(var.shared_bucket_region, "/-[0-9]+$/", "")
    permissions = "read_write"
  }
}
