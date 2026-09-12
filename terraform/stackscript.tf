locals {
  # Long single-line base64 gets mangled in transit to the instance; wrap
  # to classic 76-char MIME lines (base64 -d ignores the added newlines).
  wrap76 = { for k, v in {
    app_py_b64       = base64encode(file("${path.module}/../app/app.py"))
    requirements_b64 = base64encode(file("${path.module}/../app/requirements.txt"))
    sync_site_b64    = base64encode(file("${path.module}/../app/sync-site.py"))
    service_unit_b64 = base64encode(file("${path.module}/../app/tf-preassessment.service"))
    nginx_conf_b64   = base64encode(file("${path.module}/../app/tf-preassessment-nginx.conf"))
    } : k => join("\n", [for i in range(0, ceil(length(v) / 76)) : substr(v, i * 76, 76)])
  }
}

resource "linode_stackscript" "bootstrap" {
  label       = "tfp3-${var.engineer_slug}-bootstrap"
  description = "Bootstraps the Rocky Linux 9 app node for the Terraform P2-P3 pre-assessment (${var.engineer_slug})."
  images      = [var.instance_image]
  rev_note    = "v1"
  is_public   = false

  script = templatefile("${path.module}/../stackscript/bootstrap.sh.tftpl", merge(local.wrap76, {
    # ca_cert is already a complete PEM certificate, not base64 to decode
    # (despite the provider schema's description).
    db_ca_cert_pem = linode_database_mysql_v2.db.ca_cert
  }))
}
