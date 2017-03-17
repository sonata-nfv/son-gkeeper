FROM ruby:2.2.3-slim
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev libpq-dev && \
	rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
COPY *.gemspec /app
COPY ./lib /app/lib
RUN bundle install
COPY . /app
EXPOSE 5400
WORKDIR /app
ENV PROMETHEUS_HOST prometheus
ENV PROMETHEUS_PORT 9090
ENV PORT 5400
RUN bundle install
CMD bundle exec unicorn -c ./unicorn.conf && foreman start