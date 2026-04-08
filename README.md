## arsitektur

```
Client ──► NGINX (reverse proxy + mirror)
              │                │
              ▼                ▼
            OJS          Traffic Extractor
              │                │
              ▼                ▼
          PostgreSQL      ML Service ──► Telegram Alert
```

## komponen

| Service        | Description                                                                                                           | Port                               |
| -------------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| **NGINX**      | Reverse proxy + traffic mirroring ke extractor                                                                        | `80` (host)                        |
| **OJS**        | Open Journal Systems platform                                                                                         | internal                           |
| **PostgreSQL** | Database untuk OJS                                                                                                    | internal                           |
| **Extractor**  | Traffic log extractor (Go/Gin) diclone dari [`yogarn/traffic-extractor`](https://github.com/yogarn/traffic-extractor) | `8080` (host) → `8081` (container) |
| **ML Service** | ML inference API — *not yet active*, uncomment di `docker-compose.yml`                                                | `5000`                             |

> daftar port extractor: `docker-compose.yml`, port host `8080` ke port container `8081`. Nginx di `mirror.conf` memanggil `http://extractor:8081`.

## struktur projek

```
ojs-ids-project/
├── docker-compose.yml
├── .env.example
├── nginx/
│   ├── nginx.conf
│   ├── mirror.conf
│   └── logs/
├── ojs/
│   └── Dockerfile
├── postgres/
│   └── init.sql
├── extractor/
├── dataset/
│   ├── raw_logs/
│   ├── processed/
│   └── export/
└── scripts/
    └── setup.sh
```

## cara menjalankan

### first time setup (vm baru)

jalankan:

```bash
./scripts/setup.sh
```

flow:

1. build dan jalankan container
2. install ojs melalui browser
3. config.inc.php di-copy otomatis dari container ke host
4. docker-compose.yml di-update otomatis untuk mount config
5. container restart dengan persistence aktif

setelah langkah ini, ojs tidak akan kembali ke installer saat restart.

---

### menjalankan sistem (normal run)

```bash
docker compose up -d
```

---

### update / rebuild

jika melakukan perubahan pada kode (nginx, extractor, dll):

```bash
docker compose up -d --build
```

catatan:

* config.inc.php harus sudah dimount ke container
* jika tidak, ojs akan kembali ke halaman installer

---

### recovery config

jika ojs kembali ke installer setelah restart:

1. ambil config dari container

```bash
docker cp ojs-app:/var/www/html/config.inc.php ./ojs/config.inc.php
```

2. pastikan docker-compose.yml memiliki mount berikut:

```yaml
- ./ojs/config.inc.php:/var/www/html/config.inc.php
```

3. restart container

```bash
docker compose down
docker compose up -d
```

---

### catatan penting

* jangan gunakan `docker compose down -v` kecuali ingin reset total
* setup.sh hanya digunakan untuk initial setup
* gunakan `docker compose up -d` untuk menjalankan sistem
* config.inc.php adalah file persistence utama untuk ojs

## integrating ml service

otw
