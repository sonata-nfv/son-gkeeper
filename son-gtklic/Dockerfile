FROM python:2.7
ADD requirements.txt /tmp/requirements.txt
RUN apt-get update && apt-get install -y \
        python-psycopg2
RUN pip install -r /tmp/requirements.txt

ADD . /code
WORKDIR /code

EXPOSE 5000

CMD ["python", "app.py"]

#CMD ["tail", "-f", "app.py"]
