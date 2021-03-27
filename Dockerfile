ARG HYRAX_IMAGE_VERSION=3.0.0
FROM samveralabs/hyrax-base:$HYRAX_IMAGE_VERSION as hyku

USER root
RUN apk --no-cache upgrade && \
  apk --no-cache add libxml2-dev \
  openjdk11-jre
USER app

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
RUN bundle install --jobs "$(nproc)"
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile
