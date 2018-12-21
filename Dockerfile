FROM ruby:2.5.3
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs libreoffice imagemagick unzip ghostscript && \
    rm -rf /var/lib/apt/lists/*
# If changes are made to fits version or location,
# amend `LD_LIBRARY_PATH` in docker-compose.yml accordingly.
RUN mkdir -p /opt/fits && \
    curl -fSL -o /opt/fits/fits-latest.zip https://projects.iq.harvard.edu/files/fits/files/fits-1.3.0.zip && \
    cd /opt/fits && unzip fits-latest.zip && chmod +X /opt/fits/fits.sh

RUN mkdir /data
WORKDIR /data
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
RUN bundle install
ADD . /data
RUN bundle exec rake assets:precompile
EXPOSE 3000
