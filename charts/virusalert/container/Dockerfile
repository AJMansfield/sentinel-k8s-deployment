# syntax=docker/dockerfile:1

FROM python:3.10-alpine

# Install just the dependencies first to make for better caching:
ADD requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Now install the actual project:
ADD /virusalert /virusalert
RUN pip install /virusalert

CMD [ "python3", "-m", "virusalert" ]