FROM tensorflow/tensorflow:2.4.1-gpu
LABEL maintainer="jason_anderson_professional@gmail.com"
ARG BREAK_CACHE="1"
# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=2.0.1
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG JUPYTER_HOME=/usr/local/share/jupyter
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ENV TF_CPP_MIN_LOG_LEVEL="2"

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV CUDA_VISIBLE_DEVICES=0,1,2,3

# Disable noisy "Handling signal" log messages:
ENV GUNICORN_CMD_ARGS --log-level WARNING

# AIRFLOW setup
RUN set -ex \
    && buildDeps=' \
       build-essential \
        freetds-dev \
        libkrb5-dev \
        zlib1g-dev \
        libxml2-dev \
        libsasl2-dev \
        libxml2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
	procps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        python3.6-dev \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis==3.2' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg
RUN chown -R airflow: ${AIRFLOW_USER_HOME}

RUN mkdir -p $JUPYTER_HOME
RUN chown -R airflow:airflow $JUPYTER_HOME

RUN mkdir /api
RUN chown -R airflow:airflow /api

RUN mkdir /static
RUN chown -R airflow:airflow /static

RUN mkdir -p /usr/local/etc/jupyter
RUN chown -R airflow:airflow /usr/local/etc/jupyter

RUN set -ex \
   && apt-get update -yqq \
   && apt-get install -yqq graphviz \
   && apt-get install --reinstall procps \
   && apt-get install -yqq git

EXPOSE 8080 5555 8793 18888

ENV TF_FORCE_GPU_ALLOW_GROWTH=true

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
#CMD ["bash"]
