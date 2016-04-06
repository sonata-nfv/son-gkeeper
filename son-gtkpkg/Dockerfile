FROM ruby:2.2.3
RUN mkdir -p /app
WORKDIR /app
COPY . /app
RUN bundle install --quiet
EXPOSE 5100
WORKDIR /app
ENV PORT 5100
CMD ["foreman", "start"]
