ARG LINUX_VERSION=alpine
ARG RUBY_VERSION=3.3

FROM ruby:$RUBY_VERSION-$LINUX_VERSION AS build-env

ARG RAILS_ROOT=/app/samvera/hyrax-webapp
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"
# app user env vars
ENV USER=app
ENV GROUPNAME=$USER
ENV UID=1001
ENV GID=$UID

WORKDIR $RAILS_ROOT

# Install build dependencies
RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache \
    build-base \
    gcompat \
    git \
    libxml2-dev \
    linux-headers \
    nodejs \
    openssl-dev \
    ruby-bigdecimal \
    tzdata \
    yarn

# Create app user and group
RUN addgroup --gid "$GID" "$GROUPNAME" && \
    adduser --disabled-password --home "/app" --ingroup "$GROUPNAME" --uid "$UID" $USER && \
    mkdir -p $RAILS_ROOT && \
    chown -R $UID:$GID /app && \
    echo "export PATH=${RAILS_ROOT}/bin:${PATH}" >> /etc/profile

# Install Gems & remove build artifacts
COPY --chown=$UID:$GID Gemfile* package.json yarn.lock $RAILS_ROOT/
USER $UID
RUN bundle config set deployment true && \
    bundle config set without development:test && \
    bundle install --no-cache --retry 3 && \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    rm -rf vendor/bundle/ruby/*/cache/*.gem && \
    find vendor/bundle/ruby/*/gems/ -name "*.c" -delete && \
    find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

COPY --chown=$UID:$GID config/uv/uv-config.json config/uv/uv.html $RAILS_ROOT/config/uv/
RUN mkdir -p ./public/uv && \
    yarn install --production

COPY --chown=$UID:$GID . .

RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rails secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile
RUN rm -rf node_modules tmp/cache app/assets vendor/assets spec

##### END OF build-env ########

FROM ruby:$RUBY_VERSION-$LINUX_VERSION AS hyku-web

ARG RAILS_ROOT=/app/samvera/hyrax-webapp
ENV RAILS_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"
ENV PATH="/app/samvera/hyrax-webapp/bin:${PATH}"
# app user env vars
ENV USER=app
ENV GROUPNAME=$USER
ENV UID=1001
ENV GID=$UID
WORKDIR $RAILS_ROOT

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache \
    build-base \
    curl \
    gcompat \
    git \
    libxml2-dev \
    linux-headers \
    nodejs \
    tzdata \
    vips

# Create app user and group
RUN addgroup --gid "$GID" "$GROUPNAME" && \
    adduser --disabled-password --home "/app" --ingroup "$GROUPNAME" --uid "$UID" $USER && \
    mkdir -p $RAILS_ROOT && \
    chown -R $UID:$GID /app && \
    echo "export PATH=${RAILS_ROOT}/bin:${PATH}" >> /etc/profile

USER $UID
COPY --chown=$UID:$GID --from=build-env $RAILS_ROOT $RAILS_ROOT
RUN bundle config set deployment true && \
    bundle config set without development:test

# CMD ["./bin/web"]

CMD ["sleep", "infinity"]

FROM hyku-web AS hyku-worker

WORKDIR $RAILS_ROOT

CMD ./bin/worker

# Use a Solr version with patched Log4j to address CVE-2021-44228
FROM solr:8.11.2 AS hyku-solr
ENV SOLR_USER="solr" \
    SOLR_GROUP="solr"
USER root
COPY --chown=solr:solr solr/security.json /var/solr/data/security.json
COPY --chown=solr:solr solr/conf /opt/solr/server/solr/configsets/hyku/conf
USER $SOLR_USER
