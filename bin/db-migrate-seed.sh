#!/bin/sh
set -e

db-wait.sh "$DB_HOST:$DB_PORT"
if [ "$FCREPO_HOST" ]; then
    db-wait.sh "$FCREPO_HOST:$FCREPO_PORT"
fi
db-wait.sh "$SOLR_HOST:$SOLR_PORT"

migrations_run=`PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER $DB_NAME -t -c "SELECT version FROM schema_migrations ORDER BY schema_migrations" | wc -c`
migrations_fs=`ls -l db/migrate/ | awk '{print $9}' | grep -o '[0-9]\+' | wc -c`
if [[ "$migrations_run" -lt "$migrations_fs" ]]; then
    bundle exec rails db:create
    bundle exec rails db:migrate
    bundle exec rails db:seed
fi
