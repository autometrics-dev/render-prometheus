FROM python:3.11
MAINTAINER Fiberplane <info@fiberplane.com>

RUN apt update
RUN apt install -y prometheus

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY prometheus_wrapper /usr/local/bin

CMD ["/usr/local/bin/prometheus_wrapper"]
