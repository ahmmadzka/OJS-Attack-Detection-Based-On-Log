#!/bin/bash
# skrip setup proyek ojs ids
# inisialisasi environment proyek

set -e

# script berjalan dari root proyek
cd "$(dirname "$0")/.." || { echo "error tidak menemukan root proyek" >&2; exit 1; }

echo "setup projek"

# clone repositori traffic extractor dari repo
if [ ! -d "extractor/.git" ]; then
    echo "cloning repositori traffic extractor"
    git clone https://github.com/yogarn/traffic-extractor.git extractor/
    # salin dockerfile traffic extractor
    cp scripts/extractor.Dockerfile extractor/Dockerfile
else
    echo "traffic extractor sudah diclone"
    # pastikan dockerfile ada jika folder diclone manual
    if [ ! -f "extractor/Dockerfile" ]; then
        cp scripts/extractor.Dockerfile extractor/Dockerfile
    fi
fi

# buat file .env dari template jika belum ada
if [ ! -f ".env" ]; then
    echo "membuat .env dari .env.example"
    cp .env.example .env
    echo "      >> edit .env dengan nilai yang sebenarnya"
else
    echo " .env sudah ada"
fi

# direktori yang dibutuhkan
mkdir -p nginx/logs

# container docker
docker compose up -d --build

echo "Akses OJS di: http://localhost"
echo "ML Service di: http://localhost:5000"
echo "Extractor di:  http://localhost:8080"
