import os
import sys

import boto3

ENV_FILE = "/etc/tf-preassessment/env"


def load_env_file(path):
    """Parse KEY=VALUE lines without shell involvement.

    These secrets may contain $ or backticks; sourcing this file in bash
    would let those get re-interpreted.
    """
    env = dict(os.environ)
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                env[key.strip()] = value.strip()
    return env


ENV = load_env_file(ENV_FILE)
OBJ_ACCESS_KEY = ENV["OBJ_ACCESS_KEY"]
OBJ_SECRET_KEY = ENV["OBJ_SECRET_KEY"]
OBJ_BUCKET = ENV["OBJ_BUCKET"]
OBJ_REGION = ENV["OBJ_REGION"]
ENGINEER_SLUG = ENV["ENGINEER_SLUG"]
SITE_DIR = ENV.get("SITE_DIR", "/opt/tf-preassessment/site")

PREFIX = f"{ENGINEER_SLUG}/site/"


def main():
    client = boto3.client(
        "s3",
        endpoint_url=f"https://{OBJ_REGION}.linodeobjects.com",
        aws_access_key_id=OBJ_ACCESS_KEY,
        aws_secret_access_key=OBJ_SECRET_KEY,
    )

    os.makedirs(SITE_DIR, exist_ok=True)

    paginator = client.get_paginator("list_objects_v2")
    synced = 0
    for page in paginator.paginate(Bucket=OBJ_BUCKET, Prefix=PREFIX):
        for obj in page.get("Contents", []):
            rel_path = obj["Key"][len(PREFIX):]
            if not rel_path:
                continue
            dest_path = os.path.join(SITE_DIR, rel_path)
            os.makedirs(os.path.dirname(dest_path) or SITE_DIR, exist_ok=True)
            client.download_file(OBJ_BUCKET, obj["Key"], dest_path)
            synced += 1

    print(f"synced {synced} object(s) from s3://{OBJ_BUCKET}/{PREFIX} to {SITE_DIR}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"sync failed: {exc}", file=sys.stderr)
        sys.exit(1)
