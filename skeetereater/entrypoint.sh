#!/bin/sh

cat > $HOME/.pgpass <<EOF
${SKEETER_DB_HOST}:*:*:${SKEETER_DB_USER}:${SKEETER_DB_PASS}
EOF
chmod 600 $HOME/.pgpass

export PGHOST=$SKEETER_DB_HOST
export PGUSER=$SKEETER_DB_USER

echo 'waiting for database'
while ! psql postgres -c 'select 1' > /dev/null 2>&1; do
	sleep 1
done
echo 'database is up'

if ! psql ${SKEETER_DB_NAME} -c 'select 1' > /dev/null 2>&1; then
	echo 'creating database'
	psql ${SKEETER_DB_USER} < /etc/skeeter/schema.sql
fi

exec "$@"
