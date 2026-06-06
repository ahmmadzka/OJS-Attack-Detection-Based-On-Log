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

    if ! grep -Eqi "^installed[[:space:]]*=[[:space:]]*on" "$CONFIG_VOL"; then
        echo "[entrypoint] invalid config in volume"
        exit 1
    fi

    rm -rf "$CONFIG_SRC"

    if ln -s "$CONFIG_VOL" "$CONFIG_SRC"; then
        if [ ! -L "$CONFIG_SRC" ] || [ ! -r "$CONFIG_SRC" ]; then
            echo "[entrypoint] symlink verification failed"
            exit 1
        fi
        echo "[entrypoint] config restored from volume"
    else
        echo "[entrypoint] failed restoring config"
        exit 1
    fi

else
    echo "[entrypoint] no persisted config found, waiting for installation"
fi

(
    for i in $(seq 1 360); do
        sleep 5

        if [ -f "$CONFIG_SRC" ] && \
            [ ! -L "$CONFIG_SRC" ] && \
            grep -Eqi "^installed[[:space:]]*=[[:space:]]*on" "$CONFIG_SRC" && \
            [ ! -f "$CONFIG_VOL" ]; then

            echo "[watcher] install detected, saving config..."
            sleep 2

            if cp "$CONFIG_SRC" "$CONFIG_VOL"; then
                chown apache:apache "$CONFIG_VOL"
            else
                echo "[watcher] failed copying config"
                exit 1
            fi

            rm -rf "$CONFIG_SRC"

            if ln -s "$CONFIG_VOL" "$CONFIG_SRC"; then
                echo "[watcher] config persisted to volume"
            else
                echo "[watcher] failed creating config symlink"
                exit 1
            fi

            break
        fi
    done
    echo "[watcher] exiting"
) &

exec httpd -D FOREGROUND