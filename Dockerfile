ARG HYRAX_IMAGE_VERSION=hyrax-v5.2.0
FROM ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_IMAGE_VERSION AS hyku-web

USER root
RUN git config --system --add safe.directory \*
ENV PATH="/app/samvera/hyrax-webapp/bin:${PATH}"

USER app
ENV HOME=/app/samvera
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV MALLOC_CONF='dirty_decay_ms:1000,narenas:2,background_thread:true'

ENV TESSDATA_PREFIX=/app/samvera/tessdata
ADD https://github.com/tesseract-ocr/tessdata_best/blob/main/eng.traineddata?raw=true /app/samvera/tessdata/eng_best.traineddata

COPY --chown=1001:101 Gemfile /app/samvera/hyrax-webapp/
COPY --chown=1001:101 Gemfile.lock /app/samvera/hyrax-webapp/
RUN bundle install --jobs "$(nproc)"

ARG APP_PATH=.
COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp

RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rails secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install
CMD ./bin/web

FROM hyku-web AS hyku-worker
CMD ./bin/worker

FROM solr:8.3 AS hyku-solr
ENV SOLR_USER="solr" \
    SOLR_GROUP="solr"
USER root
COPY --chown=solr:solr solr/security.json /var/solr/data/security.json
USER $SOLR_USER
