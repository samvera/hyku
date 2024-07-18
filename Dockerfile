ARG HYRAX_IMAGE_VERSION=hyrax-v5.0.1
FROM ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_IMAGE_VERSION as hyku-base

USER root

RUN apk --no-cache upgrade && \
  apk --no-cache add \
    bash \
    cmake \
    exiftool \
    ffmpeg \
    git \
    imagemagick \
    less \
    libreoffice \
    libreoffice-lang-uk \
    libxml2-dev \
    mediainfo \
    nodejs \
    openjdk17-jre \
    openjpeg-dev \
    openjpeg-tools \
    perl \
    poppler \
    poppler-utils \
    postgresql-client \
    rsync \
    screen \
    tesseract-ocr \
    vim \
    yarn \
  && echo "******** Packages Installed *********"

# Build and install ImageMagick
RUN wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.0-57.tar.gz \
    && tar xf 7.1.0-57.tar.gz \
    && cd ImageMagick-7.1.0-57 \
    && ./configure \
    && make \
    && make install \
    && cd $OLDPWD \
    && rm -rf ImageMagick-7.1.0-57 \
    && rm -rf 7.1.0-57.tar.gz

# Install "best" training data for Tesseract
RUN echo "📚 Installing Tesseract Best (training data)!" && \
    cd /usr/share/tessdata/ && \
    wget https://github.com/tesseract-ocr/tessdata_best/raw/main/eng.traineddata -O eng_best.traineddata

ARG VIPS_VERSION=8.11.3

RUN set -x -o pipefail \
    && wget -O- https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar xzC /tmp \
    && apk --no-cache add \
     libjpeg-turbo-dev libpng-dev tiff-dev librsvg-dev libgsf-dev libimagequant-dev \
    && apk add --virtual vips-dependencies build-base \
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
    wget https://github.com/harvard-lts/fits/releases/download/1.5.5/fits-1.5.5.zip -O fits.zip && \
    unzip fits.zip && \
    rm fits.zip && \
    chmod a+x /app/fits/fits.sh
ENV PATH="${PATH}:/app/fits"
# Change the order so exif tool is better positioned and use the biggest size if more than one
# size exists in an image file (pyramidal tifs mostly)
COPY --chown=1001:101 ./ops/fits.xml /app/fits/xml/fits.xml
COPY --chown=1001:101 ./ops/exiftool_image_to_fits.xslt /app/fits/xml/exiftool/exiftool_image_to_fits.xslt
RUN ln -sf /usr/lib/libmediainfo.so.0 /app/fits/tools/mediainfo/linux/libmediainfo.so.0 && \
  ln -sf /usr/lib/libzen.so.0 /app/fits/tools/mediainfo/linux/libzen.so.0

COPY --chown=1001:101 ./bin/db-migrate-seed.sh /app/samvera/

ONBUILD ARG APP_PATH=.
ONBUILD COPY --chown=1001:101 $APP_PATH/Gemfile* /app/samvera/hyrax-webapp/
ONBUILD RUN git config --global --add safe.directory /app/samvera && \
  bundle install --jobs "$(nproc)"

ONBUILD COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp

FROM hyku-base as hyku-web
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install

CMD ./bin/web

FROM hyku-web as hyku-worker
CMD ./bin/worker
