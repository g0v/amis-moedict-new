FROM debian:bullseye
RUN apt-get update
RUN apt-get install -y git ca-certificates locales curl debian-archive-keyring g++ gcc make dpkg-dev
RUN echo 'zh_TW.UTF-8 UTF-8' >> /etc/locale.gen
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
RUN locale-gen
RUN apt-get install -y php php-mysql php-pgsql libapache2-mod-rpaf php-fpm apache2 php-curl php-gd php-mbstring php-xml composer
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install yarn
RUN apt-get install -y ruby ruby-dev
RUN apt-get install -y python3 python3-pip python3-dev libpq-dev gunicorn
RUN apt-get install -y sysvinit-core
RUN update-rc.d -f apache2 remove
RUN update-rc.d -f php7.4-fpm remove
RUN mkdir /run/php/
COPY config/ /

# 以上是來自 middle2 dockerfile
# https://github.com/middle2tw/middle2/blob/master/dockers/Dockerfile

# 目錄設定同 middle2
# https://github.com/middle2tw/middle2/blob/master/webdata/models/GitHelper.php#L112-L115
WORKDIR /srv/web

ENV PORT="8889" \
    BUNDLE_PATH="/bundle" \
    BUNDLE_BIN="/bundle/bin" \
    BUNDLE_APP_CONFIG="/bundle" \
    GEM_HOME="/bundle/global" \
    PATH="/bundle/bin:/bundle/global/bin:${PATH}"
EXPOSE ${PORT}

# git push middle2 後會先執行 m2-build.sh，安裝 Ruby 3.3
# https://github.com/middle2tw/middle2/blob/master/webdata/models/GitHelper.php#L131
COPY m2-build.sh /usr/local/bin/
RUN m2-build.sh

COPY docker-bin/* /usr/local/bin/
ENTRYPOINT ["bundler-wrapper", "rails-wrapper"]

CMD ["bash"]
