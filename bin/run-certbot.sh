#! /bin/sh
set -ex
exec /srv/primero/bin/certbot -d "cpims.mohr.gov.pk" --cert-name "primero" -m "primerocpims@gmail.com" -p "primero" "${@}"
