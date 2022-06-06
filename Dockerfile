ARG HYRAX_IMAGE_VERSION=3.1.0
FROM ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_IMAGE_VERSION as hyku-base

USER root

ARG EXTRA_APK_PACKAGES="openjdk11-jre ffmpeg"
RUN apk --no-cache upgrade && \
  apk --no-cache add \
    libxml2-dev \
    mediainfo \
    perl \
    poppler \
    poppler-utils \
    tesseract-ocr \
    openjpeg-dev \
    openjpeg-tools \
    nodejs \
    yarn \
    postgresql-client \
    $EXTRA_APK_PACKAGES

RUN wget https://imagemagick.org/download/ImageMagick.tar.gz && \
    tar xf ImageMagick.tar.gz \
    && apk --no-cache add \
      libjpeg-turbo openjpeg libpng tiff librsvg libgsf libimagequant poppler-qt5-dev \
    && cd ImageMagick-* \
    && ./configure \
    && make install

ARG VIPS_VERSION=8.11.3

RUN set -x -o pipefail \
    && wget -O- https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar xzC /tmp \
    && apk --no-cache add \
     libjpeg-turbo openjpeg libpng tiff librsvg libgsf libimagequant poppler-qt5-dev \
    && apk add --virtual vips-dependencies build-base \
     libjpeg-turbo-dev libpng-dev tiff-dev librsvg-dev libgsf-dev libimagequant-dev \
    && cd /tmp/vips-${VIPS_VERSION} \
    && ./configure --prefix=/usr \
                   --disable-static \
                   --disable-dependency-tracking \
                   --enable-silent-rules \
    && make -s install-strip \
    && cd $OLDPWD \
    && rm -rf /tmp/vips-${VIPS_VERSION} \
    && apk del --purge vips-dependencies \
    && rm -rf /var/cache/apk/*

USER app

RUN mkdir -p /app/fits && \
    cd /app/fits && \
    wget https://github.com/harvard-lts/fits/releases/download/1.5.0/fits-1.5.0.zip -O fits.zip && \
    unzip fits.zip && \
    rm fits.zip && \
    chmod a+x /app/fits/fits.sh
ENV PATH="${PATH}:/app/fits"
# Change the order so exif tool is better positioned and use the biggest size if more than one
# size exists in an image file (pyramidal tifs mostly)
COPY --chown=1001:101 $APP_PATH/ops/fits.xml /app/fits/xml/fits.xml
COPY --chown=1001:101 $APP_PATH/ops/exiftool_image_to_fits.xslt /app/fits/xml/exiftool/exiftool_image_to_fits.xslt
RUN ln -sf /usr/lib/libmediainfo.so.0 /app/fits/tools/mediainfo/linux/libmediainfo.so.0 && \
  ln -sf /usr/lib/libzen.so.0 /app/fits/tools/mediainfo/linux/libzen.so.0

COPY --chown=1001:101 $APP_PATH/Gemfile* /app/samvera/hyrax-webapp/
RUN bundle install --jobs "$(nproc)"
COPY --chown=1001:101 $APP_PATH/bin/db-migrate-seed.sh /app/samvera/

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp

ARG HYKU_BULKRAX_ENABLED="false"
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile

FROM hyku-base as hyku-worker
ENV MALLOC_ARENA_MAX=2
CMD bundle exec sidekiq
