FROM ruby:2.7.1
RUN apt-get update && apt-get install -qq -y build-essential git nodejs libpq-dev cmake libgit2-dev pkg-config --fix-missing --no-install-recommends
RUN apt-get install -y --no-install-recommends vim htop wget tar

RUN mkdir /app
WORKDIR /app

RUN gem install bundler --no-document
RUN bundle config git.allow_insecure true
RUN bundle config set with 'development'
COPY Gemfile ./
COPY Gemfile.lock ./

RUN bundle check || bundle install --jobs 20 --retry 5

COPY . /app

#ENV BUNDLE_APP_CONFIG /bundle
#ENV BUNDLE_BIN /bundle/bin
#ENV PATH $GEM_HOME/bin:$PATH
