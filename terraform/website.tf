resource "linode_object_storage_object" "index_html" {
  bucket     = var.shared_bucket_label
  region     = var.shared_bucket_region
  access_key = linode_object_storage_key.app.access_key
  secret_key = linode_object_storage_key.app.secret_key
  key        = "${var.engineer_slug}/site/index.html"
  content = templatefile("${path.module}/../site/index.html.tftpl", {
    engineer_slug = var.engineer_slug
    site_version  = var.site_version
  })
  content_type = "text/html"
  acl          = "public-read"
}

resource "linode_object_storage_object" "site_version" {
  bucket       = var.shared_bucket_label
  region       = var.shared_bucket_region
  access_key   = linode_object_storage_key.app.access_key
  secret_key   = linode_object_storage_key.app.secret_key
  key          = "${var.engineer_slug}/site/site-version.txt"
  content      = "${var.site_version}\n"
  content_type = "text/plain"
  acl          = "public-read"
}
