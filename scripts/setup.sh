#!/bin/bash
# setup.sh - Skrip Setup Proyek OJS IDS
# Skrip ini utk menginisialisasi environment proyek.

set -e

# Pastikan script selalu berjalan dari root proyek
cd "$(dirname "$0")/.." || { echo "ERROR: Tidak dapat menemukan root proyek." >&2; exit 1; }

echo "Setup Proyek OJS IDS"

# 1. Klon repositori traffic-extractor jika belum ada
if [ ! -d "extractor/.git" ]; then
    echo "[1/4] Mengkloning repositori traffic-extractor..."
    git clone https://github.com/yogarn/traffic-extractor.git extractor/
    # Salin Dockerfile karena repo traffic-extractor tidak menyertakannya
    cp scripts/extractor.Dockerfile extractor/Dockerfile
else
    echo "[1/4] traffic-extractor sudah diklon, dilewati..."
    # Pastikan Dockerfile tetap ada (jika folder diklon manual)
    if [ ! -f "extractor/Dockerfile" ]; then
        cp scripts/extractor.Dockerfile extractor/Dockerfile
    fi
fi

# 2. Buat file .env dari template jika belum ada
if [ ! -f ".env" ]; then
    echo "[2/4] Membuat .env dari .env.example..."
    cp .env.example .env
    echo "      >> Silakan edit .env dengan nilai yang sebenarnya!"
else
    echo "[2/4] .env sudah ada, dilewati..."
fi

# 3. Buat direktori yang dibutuhkan
echo "[3/4] Memastikan direktori yang dibutuhkan ada..."
mkdir -p nginx/logs
mkdir -p dataset/raw_logs
mkdir -p dataset/processed
mkdir -p dataset/export

# 4. Jalankan container
echo "[4/4] Memulai container Docker..."
docker compose up -d --build

echo "Akses OJS di: http://localhost"
echo "ML Service di: http://localhost:5000"
echo "Extractor di:  http://localhost:8080"
