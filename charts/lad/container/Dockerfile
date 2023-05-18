# syntax=docker/dockerfile:1

FROM python:3.6-alpine

RUN apk add --no-cache\
 gcc gfortran py3-pip build-base wget musl-dev openblas-dev freetype-dev libpng-dev zlib-dev\
 llvm10 llvm10-test-utils llvm10-dev\
 tiff-dev jpeg-dev openjpeg-dev zlib-dev freetype-dev lcms2-dev\
 libwebp-dev tcl-dev tk-dev harfbuzz-dev fribidi-dev libimagequant-dev\
 libxcb-dev libpng-dev\
 git\
 py3-pip\
 py3-boto3\
 py3-cryptography\
 py3-flask\
 py3-gunicorn\
 py3-matplotlib\
 py3-mysqlclient\
 py3-numpy\
 py3-pandas\
 py3-pillow\
 py3-prometheus-client\
 py3-scikit-learn\
 py3-scipy\
 py3-tqdm\
 py3-yaml

RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

RUN pip3 install git+https://github.com/AICoE/log-anomaly-detector.git
