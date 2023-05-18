# syntax=docker/dockerfile:1

FROM python:3.6

RUN apt-get update
RUN apt-get install\
 python3-elasticsearch\
 python3-gensim\
 python3-matplotlib\
 python3-numpy\
 python3-pandas\
 python3-scikit-learn\
 python3-scipy\
 python3-tqdm\
 python3-prometheus-client\
 python3-sompy\
 python3-boto3\
 python3-Flask\
 python3-Click\
 python3-pyyaml\
 python3-Flask-SQLAlchemy\
 python3-PyMySQL\
 python3-numba\
 python3-kafka-python\
 python3-jaeger-client\
 python3-opentracing_instrumentation\
 python3-cryptography\
 python3-prometheus_flask_exporter\
 python3-gunicorn

# RUN apk add --no-cache\
# #  gcc gfortran py3-pip build-base wget musl-dev openblas-dev freetype-dev libpng-dev zlib-dev\
# #  llvm10 llvm10-test-utils llvm10-dev\
# #  tiff-dev jpeg-dev openjpeg-dev zlib-dev freetype-dev lcms2-dev\
# #  libwebp-dev tcl-dev tk-dev harfbuzz-dev fribidi-dev libimagequant-dev\
# #  libxcb-dev libpng-dev\
#  git\
#  py3-pip\
#  py3-boto3\
#  py3-click\
#  py3-cryptography\
#  py3-flask\
#  py3-gunicorn\
#  py3-matplotlib\
#  py3-mysqlclient\
#  py3-numpy\
#  py3-pandas\
#  py3-pillow\
#  py3-prometheus-client\
#  py3-scikit-learn\
#  py3-scipy\
#  py3-tqdm\
#  py3-yaml\
#  py3-setuptools\
#  py3-wheel

# ADD ./log-anomaly-detector /temp/log-anomaly-detector
# RUN mv /usr/bin/make /usr/bin/make.bak
# COPY make /usr/bin/make

# RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

RUN pip3 install --install-option="--jobs=12" --verbose git+https://github.com/AICoE/log-anomaly-detector.git
# RUN python3 -m pip install --verbose /temp/log-anomaly-detector
#git+https://github.com/AICoE/log-anomaly-detector.git
