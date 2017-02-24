FROM nginx
MAINTAINER Felipe Vicens <ATOS>
COPY default.conf /etc/nginx/conf.d/default.conf
COPY default-ssl.conf /etc/nginx/conf.d/default-ssl.conf
ADD ./setenv.sh /
ADD ./docker-entrypoint.sh /
EXPOSE 80 443
CMD ["/docker-entrypoint.sh"]
