# ARG HYRAX_IMAGE_VERSION=v.5.0.4
# FROM ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_IMAGE_VERSION AS hyku-base
FROM ruby:3.2-bookworm AS hyku-base
USER root

RUN apt update && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y --no-install-recommends \
    build-essential \
    curl \
    exiftool \
    ffmpeg \
    git \
    imagemagick \
    less \
    libgsf-1-dev \
    libimagequant-dev \
    libjemalloc2 \
    libjpeg62-turbo-dev \
    libopenjp2-7-dev \
    libopenjp2-tools \
    libpng-dev \
    libpoppler-cpp-dev \
    libpoppler-dev \
    libpoppler-glib-dev \
    libpoppler-private-dev \
    libpoppler-qt5-dev \
    libreoffice \
    libreoffice-l10n-uk \
    librsvg2-dev \
    libtiff-dev \
    libvips-dev \
    libvips-tools \
    libwebp-dev \
    libxml2-dev \
    mediainfo \
    netcat-openbsd \
    nodejs \
    perl \
    poppler-utils \
    postgresql-client \
    rsync \
    ruby-grpc \
    screen \
    tesseract-ocr \
    tzdata \
    vim \
    zip \
    && \
    npm install --global yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/lib/*-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2 && \
    echo "******** Packages Installed *********"

ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV MALLOC_CONF='dirty_decay_ms:1000,narenas:2,background_thread:true'
RUN wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.0-57.tar.gz \
    && tar xf 7.1.0-57.tar.gz \
    && cd ImageMagick* \
    && ./configure \
    && make install \
    && ldconfig /usr/local/lib \
    && cd $OLDPWD \
    && rm -rf ImageMagick*

# Install "best" training data for Tesseract
RUN echo "📚 Installing Tesseract Best (training data)!" && \
    mkdir -p /usr/share/tessdata/ && \
    cd /usr/share/tessdata/ && \
    wget https://github.com/tesseract-ocr/tessdata_best/blob/main/eng.traineddata?raw=true -O eng_best.traineddata

RUN useradd -m -u 1001 -U -s /bin/bash --home-dir /app app && \
    mkdir -p /app/samvera/hyrax-webapp && \
    chown -R app:app /app && \
    echo "export PATH=/app/samvera/hyrax-webapp/bin:${PATH}" >> /etc/bash.bashrc

USER app
WORKDIR /app/samvera/hyrax-webapp

# Bundle the gems once in base to make faster builds
COPY --chown=1001:101 Gemfile /app/samvera/hyrax-webapp/
COPY --chown=1001:101 Gemfile.lock /app/samvera/hyrax-webapp/
RUN git config --global --add safe.directory /app/samvera && \
    bundle install --jobs "$(nproc)"

# RUN mkdir -p /app/fits && \
#     cd /app/fits && \
#     wget https://github.com/harvard-lts/fits/releases/download/1.5.5/fits-1.5.5.zip -O fits.zip && \
#     unzip fits.zip && \
#     rm fits.zip && \
#     chmod a+x /app/fits/fits.sh
# ENV PATH="${PATH}:/app/fits"
# # Change the order so exif tool is better positioned and use the biggest size if more than one
# # size exists in an image file (pyramidal tifs mostly)
# COPY --chown=1001:101 ./ops/fits.xml /app/fits/xml/fits.xml
# COPY --chown=1001:101 ./ops/exiftool_image_to_fits.xslt /app/fits/xml/exiftool/exiftool_image_to_fits.xslt
# RUN ln -sf /usr/lib/libmediainfo.so.0 /app/fits/tools/mediainfo/linux/libmediainfo.so.0 && \
#     ln -sf /usr/lib/libzen.so.0 /app/fits/tools/mediainfo/linux/libzen.so.0
ENV PATH="/app/samvera/hyrax-webapp/bin:/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ONBUILD ARG APP_PATH=.
ONBUILD COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp
ONBUILD RUN bundle install --jobs "$(nproc)"

FROM hyku-base AS hyku-web
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install
CMD ./bin/web

FROM hyku-web AS hyku-worker
CMD ./bin/worker

FROM solr:8.3 AS hyku-solr
ENV SOLR_USER="solr" \
    SOLR_GROUP="solr"
USER root
COPY --chown=solr:solr solr/security.json /var/solr/data/security.json
USER $SOLR_USER
