FROM ruby:2.2.3
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile /app/
RUN bundle install --quiet
COPY . /app
EXPOSE 4567
WORKDIR /app
#ENTRYPOINT ["bash"]
ENV PORT 4567
CMD ["ruby", "app/son_gtk_gui.rb"]
