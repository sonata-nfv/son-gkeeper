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
ENV PUSHGATEWAY_HOST prometheus
ENV PUSHGATEWAY_PORT 9091
ENV PORT 5400
CMD ["foreman", "start"]
