FROM ubuntu:xenial-20180525

RUN groupadd -r uwsgi && useradd -r -g uwsgi uwsgi

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV CODE_DIR /var/code

## START: GOSU
ENV GOSU_VERSION 1.10
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && for server in $(shuf -e ha.pool.sks-keyservers.net \
    hkp://p80.pool.sks-keyservers.net:80 \
    keyserver.ubuntu.com \
    hkp://keyserver.ubuntu.com:80 \
    pgp.mit.edu) ; do \
    gpg --keyserver $server --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
    done \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove ca-certificates

## END: GOSU

RUN mkdir ${CODE_DIR} && chown -R uwsgi:uwsgi ${CODE_DIR}
WORKDIR ${CODE_DIR}

RUN apt-get install -y software-properties-common

RUN add-apt-repository ppa:deadsnakes/ppa && apt-get update \
    && apt-get install -y --no-install-recommends python3.6-dev libmysqlclient-dev gcc \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 2

ENV PYTHON_PIP_VERSION 10.0.1
RUN wget -O /tmp/get-pip.py 'https://bootstrap.pypa.io/get-pip.py' \
    && python3 /tmp/get-pip.py "pip==$PYTHON_PIP_VERSION" \
    && rm /tmp/get-pip.py \
    && pip3 install --no-cache-dir --upgrade --force-reinstall "pip==$PYTHON_PIP_VERSION"

RUN pip3 install --no-cache-dir setuptools==34.3.2 uwsgi==2.0.14

COPY requirements.txt ${CODE_DIR}/requirements.txt
RUN pip3 install -r requirements.txt

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

COPY . ${CODE_DIR}

ENV FLASK_APP main.py
RUN chown -R uwsgi:uwsgi ${CODE_DIR}

COPY docker-entrypoint.sh /
RUN chmod +x docker-entrypoint.sh \
    && chown uwsgi:uwsgi docker-entrypoint.sh
COPY dev-server.sh /
RUN chmod +x dev-server.sh \
    && chown uwsgi:uwsgi dev-server.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]
CMD ["uwsgi"]