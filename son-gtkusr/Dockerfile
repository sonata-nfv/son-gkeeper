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
ENV KEYCLOAK_ADDRESS sonata.i2cat.net
ENV KEYCLOAK_PORT 8080
ENV KEYCLOAK_PATH auth
#RUN rake yard
ENV PORT 5000
EXPOSE 5000
WORKDIR /app
ENV USER_MANAGEMENT_URL http://son-gtkpkg:5150
CMD ["rake", "start"]
