FROM python:2.7
ADD requirements.txt /tmp/requirements.txt
RUN apt-get update && apt-get install -y \
        python-psycopg2 \
        postgresql-9.4
RUN pip install -r /tmp/requirements.txt


USER postgres
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER sonata WITH PASSWORD 'sonata';"

RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE DATABASE LicenseManager;"

RUN    /etc/init.d/postgresql start &&\
    psql --command "GRANT ALL PRIVILEGES ON DATABASE LicenseManager TO sonata;"

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

ADD . /code
WORKDIR /code
EXPOSE 5000
EXPOSE 5432


CMD ["/usr/lib/postgresql/9.4/bin/postgres", "-D", "/etc/postgresql/9.4/main/pg_hba.conf", "-c", "config_file=/etc/postgresql/9.4/main/postgresql.conf"]

#CMD ["python", "models.py"]
