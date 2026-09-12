variable "engineer_slug" {
  description = "Your engineer slug, e.g. juan-dela-cruz. Used in resource names, the object storage folder, and the on-box sudo username."
  type        = string
}

variable "region" {
  description = "Linode region for the instance and Managed MySQL database, e.g. us-mia."
  type        = string
}

variable "instance_type" {
  description = "Linode plan for the app instance."
  type        = string
  default     = "g6-nanode-1"
}

variable "instance_image" {
  description = "Base image for the app instance. Must be Rocky Linux 9 or another approved RHEL-compatible image."
  type        = string
  default     = "linode/rocky9"
}

variable "ssh_public_key" {
  description = "Your SSH public key contents, used for authorized_keys. No root password is set."
  type        = string
}

variable "db_engine" {
  description = "Managed MySQL engine_id (e.g. mysql/8). Changing this on an existing database can fail with a 'downgrade is not supported' error even between versions that look compatible -- treat it as fixed once the database exists."
  type        = string
  default     = "mysql/8"
}

variable "db_type" {
  description = "Linode plan for the Managed MySQL database."
  type        = string
  default     = "g6-nanode-1"
}

variable "db_cluster_size" {
  description = "Number of nodes in the Managed MySQL cluster."
  type        = number
  default     = 1
}

variable "db_name" {
  description = "Application database name created inside the Managed MySQL cluster."
  type        = string
  default     = "tfpreassessment"
}

variable "db_allow_list" {
  description = "CIDRs allowed to connect to the Managed MySQL database. Defaults open because the instance's IP isn't known until after it's created."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tfapp_user" {
  description = "System user the Flask service runs as."
  type        = string
  default     = "tfapp"
}

variable "site_version" {
  description = "Initial site-version.txt content uploaded to Object Storage."
  type        = string
  default     = "v1"
}

# --- Shared resources (created once by a single teammate) --------------------

variable "shared_firewall_id" {
  description = "ID of the shared Linode Cloud Firewall to attach this instance to."
  type        = number
}

variable "shared_bucket_label" {
  description = "Label of the shared Linode Object Storage bucket."
  type        = string
}

variable "shared_bucket_region" {
  description = "Region of the shared Object Storage bucket, e.g. ap-south-1. Also used as the Object Storage endpoint prefix (<region>.linodeobjects.com)."
  type        = string
}
