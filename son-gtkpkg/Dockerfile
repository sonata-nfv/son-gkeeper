FROM ruby:2.2.3-slim
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev && \
	rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5100
WORKDIR /app
ENV CATALOGUE_URL http://catalogues:4002/catalogues
ENV PORT 5100
CMD ["foreman", "start"]