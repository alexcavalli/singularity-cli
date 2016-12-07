FROM ruby:2.3

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY singularity-cli.gemspec /usr/src/app/
RUN bundle install

COPY . /usr/src/app
