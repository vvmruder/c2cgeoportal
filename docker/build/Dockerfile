FROM camptocamp/c2cwsgiutils:1
LABEL maintainer Camptocamp "info@camptocamp.com"

RUN \
  apt-get update && \
  apt-get install --assume-yes --no-install-recommends tree apt-transport-https gettext sudo && \
  echo 'deb https://deb.nodesource.com/node_6.x jessie main' > /etc/apt/sources.list.d/nodesource.list && \
  curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo "deb http://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list && \
  curl --silent http://apt.dockerproject.org/gpg | apt-key add - && \
  echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/backport.list && \
  curl --silent https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
  apt-get update && \
  apt-get install --assume-yes --no-install-recommends nodejs docker-engine google-chrome-stable && \
  apt-get install --assume-yes --no-install-recommends --target-release=jessie-backports openjdk-8-jre-headless && \
  apt-get clean && \
  rm --recursive --force /var/lib/apt/lists/*

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION="latest"
RUN \
  curl https://chromedriver.storage.googleapis.com/2.33/chromedriver_linux64.zip > /tmp/chromedriver.zip
  unzip /tmp/chromedriver.zip -d /tmp/chromedriver/ && \
  mv /tmp/chromedriver/chromedriver /usr/bin
  chmod 755 /usr/bin/chromedriver && \
  rm -rf /tmp/chromedriver.zip

COPY requirements.txt fixversions.txt /tmp/

RUN \
  cd /tmp && \
  pip install --disable-pip-version-check --no-cache-dir --requirement requirements.txt && \
  # for mypy
  touch /usr/local/lib/python3.6/site-packages/zope/__init__.py && \
  rm --recursive --force /tmp/* /var/tmp/* /root/.cache/*

COPY run /usr/bin/
COPY sudoers /etc/

WORKDIR /src

ENV PYTHONPATH /build/venv/lib/python3.6/site-packages/

ENTRYPOINT ["run"]
