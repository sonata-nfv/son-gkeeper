FROM ruby:2.2.3-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
	build-essential && \
	rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5100
WORKDIR /app
ENV PORT 5100
CMD ["foreman", "start"]
