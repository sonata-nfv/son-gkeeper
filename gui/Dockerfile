FROM ubuntu:14.04

# Install apache
RUN apt-get update && apt-get install -y apache2

COPY ./ /var/www/html/

RUN ls -la /var/www/html/*
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 4000
ADD run.sh /run.sh
RUN chmod 0755 /run.sh
CMD ["./run.sh"]

