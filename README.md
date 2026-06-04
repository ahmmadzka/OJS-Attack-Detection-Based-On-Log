# OJS Attack Detection Based On Log

Real-time attack monitoring system for Open Journal Systems (OJS) using log extraction, machine learning integration, and dashboard visualization.

## Components

This deployment consists of:

* Open Journal Systems (OJS) 3.3.0-14
* PostgreSQL
* Nginx Reverse Proxy
* Traffic Extractor
* ML Attack Detection Integration

All services are deployed using Docker Compose.

---

## Prerequisites

Install:

* Docker
* Docker Compose v2+
* Git

Verify installation:

```bash
docker --version
docker compose version
git --version
```

---

## Clone Repository

```bash
git clone https://github.com/ahmmadzka/OJS-Attack-Detection-Based-On-Log.git

cd OJS-Attack-Detection-Based-On-Log
```

---

## Verify Extractor Directory

This deployment requires the Traffic Extractor source code to be present inside the project directory.

Expected structure:

```text
OJS-Attack-Detection-Based-On-Log
├── extractor
├── nginx
├── ojs
├── postgres
├── scripts
├── docker-compose.yml
└── README.md
```

Verify:

```bash
ls extractor
```

Expected output:

```text
app.go
main.go
go.mod
go.sum
Dockerfile
...
```

If the directory does not exist, clone the extractor repository into the project:

```bash
git clone \
https://github.com/ManutKataPakEko/traffic-extractor.git \
extractor
```

---

## Configure Environment

Create environment file:

```bash
cp .env.example .env
```

Edit configuration:

```bash
nano .env
```

Configure:

* PostgreSQL credentials
* ML service integration
* Dashboard integration
* Telegram settings (if used)

---

## Prepare Runtime Directories

Create nginx log directory:

```bash
mkdir -p nginx/logs
```

Create extractor log file:

```bash
touch extractor/requests.log
```

---

## Build and Start Services

```bash
docker compose up -d --build
```

Verify:

```bash
docker ps
```

Expected containers:

```text
ojs-nginx
ojs-app
ojs-postgres
traffic-extractor
```

---

## First-Time OJS Installation

Open:

```text
http://SERVER_IP
```

or

```text
http://localhost
```

Complete the OJS installation wizard.

After installation completes, the configuration will automatically be persisted using Docker Volumes.

No manual editing of `config.inc.php` is required.

---

## Persistence

Runtime data is stored in Docker Volumes:

| Volume        | Purpose                  |
| ------------- | ------------------------ |
| postgres-data | PostgreSQL database      |
| ojs-files     | Uploaded journal files   |
| ojs-public    | Public assets            |
| ojs-plugins   | Installed plugins        |
| ojs-config    | Active OJS configuration |

These volumes survive:

```bash
docker compose down
docker compose up -d
```

and

```bash
docker compose up -d --build
```

---

## Important Warning

Do NOT run:

```bash
docker compose down -v
```

This command removes:

* Database
* Uploaded journal files
* Public assets
* Plugins
* OJS configuration

and will reset the deployment.

Use:

```bash
docker compose down
```

instead.

---

## Verification

Check OJS:

```bash
curl http://localhost
```

Check PostgreSQL:

```bash
docker exec ojs-postgres pg_isready
```

Check OJS installation status:

```bash
docker exec ojs-app \
grep "^installed" \
/var/www/html/config.inc.php
```

Expected:

```text
installed = On
```

---

## Logs

View all logs:

```bash
docker compose logs -f
```

Specific services:

```bash
docker compose logs -f nginx
docker compose logs -f ojs
docker compose logs -f postgres
docker compose logs -f extractor
```

---

## Backup

Database:

```bash
docker exec ojs-postgres \
pg_dump \
-U <POSTGRES_USER> \
-d <POSTGRES_DB> \
> backup.sql
```

Configuration:

```bash
docker cp \
ojs-app:/var/www/html/config.inc.php \
./config-runtime-backup.php
```

Uploaded files:

```bash
docker run --rm \
-v ojs-attack-detection-based-on-log_ojs-files:/data \
-v $(pwd):/backup \
alpine \
tar czf /backup/ojs-files-backup.tar.gz /data
```

---

## Updating OJS

Pull latest repository changes:

```bash
git pull
```

Rebuild containers:

```bash
docker compose up -d --build
```

Persistent data stored in Docker Volumes will remain intact.

---

## Troubleshooting

### OJS cannot connect to PostgreSQL

Check:

```bash
docker logs ojs-postgres
docker logs ojs-app
```

Verify `.env` credentials.

---

### Extractor container fails

Check:

```bash
docker logs traffic-extractor
```

Verify:

```bash
ls extractor
```

and ensure the extractor source code exists.

---

### OJS installation page keeps appearing

Verify:

```bash
docker volume ls
```

and confirm:

```text
ojs-config
postgres-data
```

still exist.

---

## OJS Version

Current deployment uses:

```text
Open Journal Systems 3.3.0-14
```
