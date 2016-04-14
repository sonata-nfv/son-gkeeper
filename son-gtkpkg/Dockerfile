FROM ruby:2.2.3
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5100
WORKDIR /app
ENV PORT 5100
CMD ["foreman", "start"]
