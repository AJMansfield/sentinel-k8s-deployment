# syntax=docker/dockerfile:1

FROM python:3.10-alpine

ADD /virusalert /virusalert
RUN pip install /virusalert

CMD [ "python3", "-m", "virusalert" ]