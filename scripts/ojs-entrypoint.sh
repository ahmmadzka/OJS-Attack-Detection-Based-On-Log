#!/bin/sh

CONFIG_VOL="/var/www/html/config-vol/config.inc.php"
CONFIG_SRC="/var/www/html/config.inc.php"

echo "[entrypoint] starting..."

echo "[entrypoint] waiting for PostgreSQL auth..."

DB_READY=false

for i in $(seq 1 60); do
    if PGPASSWORD="$OJS_DB_PASSWORD" psql \
        -h "$OJS_DB_HOST" \
        -U "$OJS_DB_USER" \
        -d "$OJS_DB_NAME" \
        -c '\q' > /dev/null 2>&1; then
        DB_READY=true
        break
    fi
    echo "[entrypoint] DB not ready ($i/60), retrying..."
    sleep 2
done

if [ "$DB_READY" != "true" ]; then
    echo "[entrypoint] PostgreSQL unreachable"
    exit 1
fi

echo "[entrypoint] proceeding..."

mkdir -p /var/www/html/config-vol
chown -R apache:apache /var/www/html/config-vol

if [ -f "$CONFIG_VOL" ]; then
    ln -s "$CONFIG_VOL" "$CONFIG_SRC"
    echo "[entrypoint] config restored from volume"
fi

(
    for i in $(seq 1 360); do
        sleep 5

        if [ -f "$CONFIG_SRC" ] && \
            [ ! -L "$CONFIG_SRC" ] && \
            grep -qi "installed *= *on" "$CONFIG_SRC" && \
            [ ! -f "$CONFIG_VOL" ]; then

            echo "[watcher] install detected, saving config..."
            sleep 2

            cp "$CONFIG_SRC" "$CONFIG_VOL"
            chown apache:apache "$CONFIG_VOL"

            rm -f "$CONFIG_SRC"
            ln -s "$CONFIG_VOL" "$CONFIG_SRC"

            echo "[watcher] config persisted to volume"
            break
        fi
    done
) &
exec httpd -D FOREGROUND
