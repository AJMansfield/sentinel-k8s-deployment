# syntax=docker/dockerfile:1

FROM python:3.6-alpine

RUN apk -U add \
    py3-boto3 \
    py3-cryptography \
    py3-flask \
    py3-gunicorn \
    py3-matplotlib \
    py3-mysqlclient \
    py3-numpy \
    py3-pandas \
    py3-prometheus-client \
    py3-scikit-learn \
    py3-scipy \
    py3-tqdm \
    py3-yaml

RUN pip install git+https://github.com/AICoE/log-anomaly-detector.git
