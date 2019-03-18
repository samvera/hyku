FROM hyku/base:latest

ADD https://time.is/just build-time
COPY ops/nginx.sh /etc/service/nginx/run
COPY ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY ops/env.conf /etc/nginx/main.d/env.conf

COPY  --chown=app . $APP_HOME

RUN /sbin/setuser app bash -l -c "set -x && \
    (bundle check || bundle install) && \
    bundle exec rake assets:precompile DB_ADAPTER=nulldb && \
    mv ./public/assets ./public/assets.new"

CMD ["/sbin/my_init"]
