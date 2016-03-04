FROM ubuntu

# Install apache
RUN apt-get update && apt-get install -y apache2

COPY * /var/www/html/

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 4000
CMD ["service", "apache2", "start"]
