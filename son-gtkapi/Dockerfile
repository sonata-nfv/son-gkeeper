FROM ruby:2.2.3-slim
RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential libcurl3 libcurl3-gnutls libcurl4-openssl-dev && \
	rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5000
WORKDIR /app
ENV PORT 5000
ENV PACKAGE_MANAGEMENT_URL http://son-gtkpkg:5100
ENV SERVICE_MANAGEMENT_URL http://son-gtksrv:5300
ENV FUNCTION_MANAGEMENT_URL http://son-gtkfnct:5500
ENV VIM_MANAGEMENT_URL http://son-gtkvim:5700
ENV RECORD_MANAGEMENT_URL http://son-gtkrec:5800
ENV LICENCE_MANAGEMENT_URL http://son-gtklic:5900
ENV KPI_MANAGEMENT_URL http://son-gtkkpi:5400
CMD ["foreman", "start"]
