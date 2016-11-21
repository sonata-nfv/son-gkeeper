#############################################################################
# Requires external Postgres DB to be running, can be another container.    #
# After is running change the settings.py to the correct connection string. #
# At last build this container                                              #
#############################################################################

FROM python:2.7
ADD requirements.txt /tmp/requirements.txt
RUN apt-get update && apt-get install -y \
        python-psycopg2 \
        postgresql-client*

RUN pip install -r /tmp/requirements.txt

ADD . /code
WORKDIR /code

EXPOSE 5000

ENV POSTGRES_PASSWORD sonata
ENV POSTGRES_USER sonata
ENV POSTGRES_DB licensemanager
ENV DATABASE_HOST 192.168.54.249
ENV DATABASE_PORT 5432
ENV PORT 5000

# Run Tests
RUN ["python", "licenseManager/tests.py"]

# Migrate Database
# Always return 0 only for the case the migrations repo is not created
RUN ["python", "manage.py", "db", "upgrade"]

# Run Server
CMD ["python", "manage.py", "runserver", "--host", "0.0.0.0"]
