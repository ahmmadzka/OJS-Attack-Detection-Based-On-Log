#!/bin/bash
# inisialisasi environment proyek

set -e

# script berjalan dari root proyek
cd "$(dirname "$0")/.." || { echo "error tidak menemukan root proyek" >&2; exit 1; }

echo "setup projek"

# bersihkan container dan volume lama (jika ada)
docker compose down -v 2>/dev/null || true

# clone repositori traffic extractor dari repo
if [ ! -d "extractor/.git" ]; then
    echo "cloning repositori traffic extractor"
    git clone https://github.com/yogarn/traffic-extractor.git extractor/
    cp scripts/extractor.Dockerfile extractor/Dockerfile
else
    echo "traffic extractor sudah diclone"
    if [ ! -f "extractor/Dockerfile" ]; then
        cp scripts/extractor.Dockerfile extractor/Dockerfile
    fi
fi

# buat file .env dari template jika belum ada
if [ ! -f ".env" ]; then
    echo "membuat .env dari .env.example"
    cp .env.example .env
    echo ""
    echo "silahkan edit file .env (nano .env)"
    echo "Sesuaikan POSTGRES_USER, POSTGRES_PASSWORD, dll"
    echo ""
    read -p "Tekan ENTER setelah selesai mengedit .env..." _
else
    echo " .env sudah ada"
fi

# direktori dan file yang dibutuhkan
mkdir -p nginx/logs
touch extractor/requests.log

# container docker
docker compose up -d --build

echo ""
echo "  Deployment selesai!"
echo "  Akses OJS di: http://localhost"
echo "  Extractor di: http://localhost:8081"
echo "  ML Service di: http://localhost:5000"
