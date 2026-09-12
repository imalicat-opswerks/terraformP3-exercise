# Terraform P2-P3 Pre-Assessment

## Submission details

| Field | Value |
|---|---|
| Engineer slug | `iverson-malicat` |
| Instance IP | `172.236.152.229` |
| Database label | `a3-tfp3-iverson-malicat-db` |
| Shared firewall ID | `163498976` |
| Shared bucket name | `a3-tfp3-shared-bucket` |
| Object Storage folder | `iverson-malicat/site/` |

## Assumptions

- "Team Setup" (shared firewall + shared bucket) already exists; this repo only takes their ID/label/region as input variables.
- The truncated pre-assessment spec line `GET /api/events/` is implemented as `GET /api/events/<engineer>`, returning that engineer's events.
- Managed MySQL does not pre-provision an application schema, so `app.py` runs `CREATE DATABASE IF NOT EXISTS` and `CREATE TABLE IF NOT EXISTS` on startup and seeds one row for the engineer slug if missing.
- One Object Storage access key per engineer is acceptable (vs. reusing a single shared key).

## Known limitations

- `getenforce` reports `Permissive` immediately after the first boot; `/etc/selinux/config` is set to `disabled`, so it reads `Disabled` from the next reboot onward.
- `db_allow_list` defaults to `0.0.0.0/0` because `linode_database_mysql_v2.db` and `linode_instance.app` would otherwise form a Terraform dependency cycle (the DB needs the instance's IP for `allow_list`; the instance needs the DB's credentials via StackScript at boot).
- `sync-site.py` only adds/updates local files; it does not delete files removed from the bucket.
- No automated tests; verification is manual (curl checks, `systemctl`, `getenforce`).

See `ARCHITECTURE.md` for layout, ownership, StackScript/secrets details, setup steps, and final-check commands.
