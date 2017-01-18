FROM ruby:2.2.3-slim
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev libpq-dev && \
	rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5300
WORKDIR /app
ENV POSTGRES_PASSWORD sonata
ENV POSTGRES_USER sonatatest
ENV DATABASE_HOST postgres
ENV DATABASE_PORT 5432
ENV MQSERVER amqp://guest:guest@broker:5672
ENV CATALOGUES_URL http://sp.int.sonata-nfv.eu:4002/catalogues
ENV PORT 5300
CMD ["foreman", "start"]
