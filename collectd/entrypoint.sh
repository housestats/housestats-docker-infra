#!/bin/sh

: ${COLLECTD_DB_HOST:=localhost}
: ${COLLECTD_DB_USER:=postgres}
: ${COLLECTD_DB_NAME:=collectd}

export COLLECTD_DB_{HOST,USER,NAME}

cat > $HOME/.pgpass <<EOF
${COLLECTD_DB_HOST}:*:*:${COLLECTD_DB_USER}:${COLLECTD_DB_PASS}
EOF
chmod 600 $HOME/.pgpass

export PGHOST=$COLLECTD_DB_HOST
export PGUSER=$COLLECTD_DB_USER

echo 'waiting for database'
while ! psql postgres -c 'select 1'; do
	sleep 1
done
echo 'database is up'

if ! psql ${COLLECTD_DB_NAME} -c 'select 1' > /dev/null 2>&1; then
	echo 'creating database'
	envtpl < /etc/collectd/schema.sql.tpl | psql ${COLLECTD_DB_USER}
fi

envtpl < /etc/collectd/collectd.conf.tpl > /etc/collectd.conf

exec "$@"
