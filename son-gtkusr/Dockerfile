FROM ruby:2.2.3-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential && \
	apt-get -y install libcurl3 libcurl3-gnutls libcurl4-openssl-dev && \
	rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app
COPY Gemfile /app/
WORKDIR /app
RUN bundle install
COPY . /app
ADD ./setenv.sh /
ADD ./docker-entrypoint.sh /
ENV PORT 5600
EXPOSE 5600
WORKDIR /app
ENV USER_MANAGEMENT_URL http://son-gtkusr:5600
CMD ["/docker-entrypoint.sh"]
