FROM ruby:2.3.1
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs libreoffice imagemagick unzip && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/fits && \
    curl -fSL -o /opt/fits-0.6.2.zip http://projects.iq.harvard.edu/files/fits/files/fits-0.6.2.zip && \
    cd /opt && unzip fits-0.6.2.zip && chmod +X fits-0.6.2/fits.sh

RUN mkdir /data
WORKDIR /data
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
RUN bundle install
ADD . /data
RUN bundle exec rake assets:precompile
EXPOSE 3000

