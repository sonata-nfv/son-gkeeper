FROM ruby:2.2.3
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app
RUN bundle install
COPY . /app
EXPOSE 5300
WORKDIR /app
ENV PORT 5300
FROM library/postgres
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD sonatatest
ENV POSTGRES_DB sonata
RUN rake db:create
RUN rake db:migrate
CMD ["foreman", "start"]
