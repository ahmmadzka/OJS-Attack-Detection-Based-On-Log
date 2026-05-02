#!/bin/bash
set -e

cd "$(dirname "$0")/.." || exit 1

echo "Setup project"

CONFIG_FILE="./ojs/config.inc.php"

# detect first run
if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    FIRST_RUN=true
    echo "First run"
else
    FIRST_RUN=false
    echo "Existing setup"
fi

# stop container (non destructive)
docker compose down 2>/dev/null || true

# clone extractor if not exist
if [ ! -d "extractor/.git" ]; then
    git clone https://github.com/ManutKataPakEko/traffic-extractor.git extractor/
    cp scripts/extractor.Dockerfile extractor/Dockerfile
fi

# env setup
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "Edit .env first"
    read -p "Press ENTER after editing..." _
fi

# prepare directories
mkdir -p nginx/logs
touch extractor/requests.log

# ── FIRST RUN ────────────────────────────────────────────────────────────────
if [ "$FIRST_RUN" = true ]; then

    touch "$CONFIG_FILE"
    chmod 666 "$CONFIG_FILE"
    echo "Created empty config.inc.php (writable)"

    # Inject mount ke docker-compose.yml
    if ! grep -q "config.inc.php:/var/www/html/config.inc.php" docker-compose.yml; then
        echo "Injecting config mount into docker-compose.yml..."
        sed -i '/ojs-public/a\      - ./ojs\/config.inc.php:\/var\/www\/html\/config.inc.php' docker-compose.yml
    fi

    # Ensure config mount is writable for installer
    if grep -q "config.inc.php:/var/www/html/config.inc.php:ro" docker-compose.yml; then
        sed -i 's#config.inc.php:/var/www/html/config.inc.php:ro#config.inc.php:/var/www/html/config.inc.php#' docker-compose.yml
    fi

    docker compose up -d --build

    # Ensure config has defaults to avoid empty encoding issues
    if [ ! -s "$CONFIG_FILE" ]; then
        echo "Seeding config.inc.php from template..."
        docker exec ojs-app sh -lc 'if [ ! -s /var/www/html/config.inc.php ]; then cat /var/www/html/config.TEMPLATE.inc.php > /var/www/html/config.inc.php; fi'
        docker cp ojs-app:/var/www/html/config.inc.php "$CONFIG_FILE"
    fi

    # Make sure installer can write config (bind mount)
    chmod 666 "$CONFIG_FILE"
    docker exec ojs-app sh -lc 'chmod 666 /var/www/html/config.inc.php'

    # Fix permissions for Apache user inside container
    docker exec ojs-app sh -lc 'chown -R apache:apache /var/www/html/public /var/www/files /var/www/html/cache'
    docker exec ojs-app sh -lc 'chmod -R 775 /var/www/html/public /var/www/files /var/www/html/cache'
    docker exec ojs-app sh -lc 'chown apache:apache /var/www/html/config.inc.php'
    docker exec ojs-app sh -lc 'chmod 664 /var/www/html/config.inc.php'

    echo ""
    echo "============================================================"
    echo "  OJS sedang berjalan."
    echo "  Buka http://localhost dan selesaikan instalasi OJS."
    echo "  Setelah selesai, tekan ENTER untuk melanjutkan..."
    echo "============================================================"
    read -p "" _

    echo "Waiting for container..."
    until docker exec ojs-app sh -lc 'test -d /var/www/html' >/dev/null 2>&1; do
        sleep 2
    done
    # Ensure config file exists in container
    docker exec ojs-app sh -lc 'touch /var/www/html/config.inc.php'

    # Cek apakah installer berhasil nulis config
    CONFIG_SIZE=$(docker exec ojs-app sh -lc 'wc -c < /var/www/html/config.inc.php 2>/dev/null || echo 0')
    INSTALLED_FLAG=$(docker exec ojs-app sh -lc "grep -E '^installed[[:space:]]*=' /var/www/html/config.inc.php | tail -n 1" 2>/dev/null || echo "")
    if [ "$CONFIG_SIZE" -gt 100 ] && echo "$INSTALLED_FLAG" | grep -qi 'On'; then
        echo "Config berhasil ditulis"
        # Sync balik ke host (untuk backup/persistent)
        docker cp ojs-app:/var/www/html/config.inc.php "$CONFIG_FILE"
        chmod 666 "$CONFIG_FILE"
        echo "Config disync ke host: $CONFIG_FILE"

        # Lock config mount to prevent overwrite on restart
        if ! grep -q "config.inc.php:/var/www/html/config.inc.php:ro" docker-compose.yml; then
            sed -i 's#config.inc.php:/var/www/html/config.inc.php#config.inc.php:/var/www/html/config.inc.php:ro#' docker-compose.yml
            echo "Config mount set to read-only"
        fi
    else
        echo "Installer tidak bisa menulis config"
        echo "Silakan copy isi config dari halaman install OJS,"
        echo "lalu paste ke file: $CONFIG_FILE"
        read -p "Tekan ENTER setelah file config diisi..." _
    fi

    echo "Restarting with persistent config..."
    docker compose down
    docker compose up -d

    echo ""
    echo "Setup complete (persistent mode active)"

# ── RESTART / DEBUG ──────────────────────────────────────────────────────────
else

    docker compose up -d

    echo ""
    echo "Container started (existing config)"
fi