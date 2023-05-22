# syntax=docker/dockerfile:1

FROM python:3.6

RUN apt-get update && apt-get install -y \
  python3-elasticsearch \
  python3-matplotlib \
  python3-numpy \
  python3-pandas \
  python3-sklearn \
  python3-scipy \
  python3-tqdm \
  python3-prometheus-client \
  python3-boto3 \
  python3-flask \
  python3-click \
  python3-yaml \
  python3-flask-sqlalchemy \
  python3-pymysql \
  python3-numba \
  python3-kafka \
  python3-opentracing \
  python3-cryptography \
  python3-gunicorn \
  && rm -rf /var/lib/apt/lists/*

RUN pip install git+https://github.com/AJMansfield/log-anomaly-detector.git
