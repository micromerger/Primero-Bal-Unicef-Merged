#! /bin/sh
set -ex
exec /srv/primero/bin/certbot -d "sindh.cpims.org.pk" --cert-name "primero" -m "sara.raza@xprolabs.com" -p "primero" "${@}"
