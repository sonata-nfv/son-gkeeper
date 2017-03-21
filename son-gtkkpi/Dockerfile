FROM ruby:2.2.3-slim
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev libpq-dev golang git jq && \
	rm -rf /var/lib/apt/lists/*
ENV GOPATH=$HOME/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin
RUN go get github.com/prometheus/prom2json
RUN go install github.com/prometheus/prom2json
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
COPY *.gemspec /app
COPY ./lib /app/lib
RUN bundle install
COPY . /app
EXPOSE 5400
WORKDIR /app
ENV PUSHGATEWAY_HOST pushgateway
ENV PUSHGATEWAY_PORT 9091
ENV PORT 5400
CMD ["foreman", "start"]
