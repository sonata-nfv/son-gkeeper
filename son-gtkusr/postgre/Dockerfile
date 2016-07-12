FROM python:2.7
RUN apt-get update && apt-get install -y \
        postgresql-9.4

USER postgres
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER sonata WITH PASSWORD 'sonata';"

RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE DATABASE UserManagement;"

RUN    /etc/init.d/postgresql start &&\
    psql --command "GRANT ALL PRIVILEGES ON DATABASE UserManagement TO sonata;"

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

EXPOSE 5432

CMD ["/usr/lib/postgresql/9.4/bin/postgres", "-D", "/etc/postgresql/9.4/main/pg_hba.conf", "-c", "config_file=/etc/postgresql/9.4/main/postgresql.conf"]
