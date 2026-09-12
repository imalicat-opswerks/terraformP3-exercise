import os

import pymysql
import pymysql.cursors
from flask import Flask, jsonify, request, send_file

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_NAME = os.environ.get("DB_NAME", "tfpreassessment")
DB_CA_CERT = os.environ.get("DB_CA_CERT", "/etc/tf-preassessment/ca-cert.pem")
ENGINEER_SLUG = os.environ.get("ENGINEER_SLUG", "unknown-engineer")
SITE_DIR = os.environ.get("SITE_DIR", "/opt/tf-preassessment/site")

app = Flask(__name__)


def _ssl_args():
    if os.path.exists(DB_CA_CERT):
        return {"ssl": {"ca": DB_CA_CERT}}
    return {}


def get_connection(database=DB_NAME):
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=database,
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=5,
        **_ssl_args(),
    )


def ensure_schema():
    bootstrap_conn = get_connection(database=None)
    try:
        with bootstrap_conn.cursor() as cur:
            cur.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}`")
        bootstrap_conn.commit()
    finally:
        bootstrap_conn.close()

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS assessment_events (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    engineer VARCHAR(64) NOT NULL,
                    message VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            cur.execute(
                "SELECT id FROM assessment_events WHERE engineer = %s LIMIT 1",
                (ENGINEER_SLUG,),
            )
            if cur.fetchone() is None:
                cur.execute(
                    "INSERT INTO assessment_events (engineer, message) VALUES (%s, %s)",
                    (ENGINEER_SLUG, "Terraform P2-P3 pre-assessment bootstrap complete"),
                )
        conn.commit()
    finally:
        conn.close()


ensure_schema()


@app.route("/")
def index():
    index_path = os.path.join(SITE_DIR, "index.html")
    if os.path.exists(index_path):
        return send_file(index_path)
    return "Site content has not synced from Object Storage yet", 503


@app.route("/healthz")
def healthz():
    try:
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        finally:
            conn.close()
        return jsonify(status="ok"), 200
    except Exception as exc:
        return jsonify(status="error", detail=str(exc)), 503


@app.route("/api/events", methods=["POST"])
def create_event():
    data = request.get_json(silent=True) or {}
    engineer = data.get("engineer")
    message = data.get("message")
    if not engineer or not message:
        return jsonify(error="engineer and message are required"), 400

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO assessment_events (engineer, message) VALUES (%s, %s)",
                (engineer, message),
            )
            event_id = cur.lastrowid
        conn.commit()
    finally:
        conn.close()

    return jsonify(id=event_id, engineer=engineer, message=message), 201


@app.route("/api/events/<engineer>")
def list_events(engineer):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, engineer, message, created_at FROM assessment_events "
                "WHERE engineer = %s ORDER BY id DESC",
                (engineer,),
            )
            rows = cur.fetchall()
    finally:
        conn.close()

    for row in rows:
        row["created_at"] = row["created_at"].isoformat()

    return jsonify(rows), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8088)
