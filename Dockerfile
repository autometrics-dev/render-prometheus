FROM python:3.11
MAINTAINER Fiberplane <info@fiberplane.com>
ARG version=2.46.0

RUN apt update
RUN apt install -y wget

RUN wget https://github.com/prometheus/prometheus/releases/download/v${version}/prometheus-${version}.linux-amd64.tar.gz

RUN tar -xvzf prometheus-${version}.linux-amd64.tar.gz -C /etc/
RUN mv /etc/prometheus-${version}.linux-amd64 /etc/prometheus
RUN ln -s /etc/prometheus/prometheus /usr/local/bin

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY prometheus_wrapper /usr/local/bin

CMD ["/usr/local/bin/prometheus_wrapper"]
