# syntax=docker/dockerfile:1-labs

FROM python:3.8

# Install just the dependencies first to make for better caching:
ADD requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Install the real deal
ADD https://github.com/AJMansfield/log-anomaly-detector.git#20230821 /opt/lad
RUN pip install -e /opt/lad

# CMD log-anomaly-detector run --config-yaml /opt/lad-config/.env_config.yaml 2>&1 | cut -c-$COLUMNS