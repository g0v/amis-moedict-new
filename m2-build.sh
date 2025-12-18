#!/bin/bash

export LANG="C.UTF-8"
export RUBY_VERSION="3.4.3" # $RUBY_VERSION 應該要跟 Gemfile 同步
export BUNDLER_VERSION="2.6.8" # $BUNDLER_VERSION 應該要跟 Gemfile.lock 同步
export PATH="/opt/rubies/ruby-$RUBY_VERSION/bin:$PATH"

# 確認 Ruby 版本，如果不是 $RUBY_VERSION，就用 ruby-build 安裝
current_ruby_version=$(ruby -v | awk '{print $2}')

if [ "$current_ruby_version" != "$RUBY_VERSION" ]; then
  set -eux; \
    apt remove -y ruby \
    ruby2.7-doc \
    ruby-xmlrpc \
    ruby-test-unit \
    ruby-power-assert \
    ruby-net-telnet \
    ruby-minitest \
    rubygems-integration

  set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      autoconf \
      patch \
      build-essential \
      rustc \
      libyaml-dev \
      libreadline6-dev \
      zlib1g-dev \
      libgmp-dev \
      libncurses5-dev \
      libgdbm6 \
      libgdbm-dev \
      libdb-dev \
      uuid-dev \
      libffi-dev \
      default-libmysqlclient-dev

  set -eux; \
    apt-get install -y --no-install-recommends \
    vim \
    ripgrep

  # 沒有 /tmp/ruby-build 時，跑 git clone 下載
  if [ ! -d "/tmp/ruby-build" ]; then
    set -eux; \
      git clone "https://github.com/rbenv/ruby-build.git" /tmp/ruby-build
  fi

  # middle2 上 openssl 會跑出 /lib64 資料夾
  # 但 macbook 上用同樣的 middle2 docker，openssl 是 /lib，先用 architecture 判斷
  if [ "$(dpkg --print-architecture)" == "amd64" ]; then
    set -eux; \
      /tmp/ruby-build/bin/ruby-build "$RUBY_VERSION" "/opt/rubies/ruby-$RUBY_VERSION" -- --with-openssl-lib="/opt/rubies/ruby-$RUBY_VERSION/openssl/lib64"
  else
    set -eux; \
      /tmp/ruby-build/bin/ruby-build "$RUBY_VERSION" "/opt/rubies/ruby-$RUBY_VERSION"
  fi

  # middle2 不知道怎麼設定 PATH，因此把 ruby 的執行檔 symlink 到 /usr/local/bin
  set -eux; \
    [ -L "/usr/local/bin/bundle" ] && unlink /usr/local/bin/bundle || echo "No bundle symlink to remove"; \
    [ -L "/usr/local/bin/bundler" ] && unlink /usr/local/bin/bundler || echo "No bundler symlink to remove"; \
    [ -L "/usr/local/bin/erb" ] && unlink /usr/local/bin/erb || echo "No erb symlink to remove"; \
    [ -L "/usr/local/bin/gem" ] && unlink /usr/local/bin/gem || echo "No gem symlink to remove"; \
    [ -L "/usr/local/bin/irb" ] && unlink /usr/local/bin/irb || echo "No irb symlink to remove"; \
    [ -L "/usr/local/bin/racc" ] && unlink /usr/local/bin/racc || echo "No racc symlink to remove"; \
    [ -L "/usr/local/bin/rake" ] && unlink /usr/local/bin/rake || echo "No rake symlink to remove"; \
    [ -L "/usr/local/bin/ruby" ] && unlink /usr/local/bin/ruby || echo "No ruby symlink to remove";

  set -eux; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/bundle"  /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/bundler" /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/erb"     /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/gem"     /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/irb"     /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/racc"    /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/rake"    /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/ruby"    /usr/local/bin/
else
  echo "Ruby version is already $RUBY_VERSION."
fi

# 確認 bundler 版本並安裝
# $BUNDLER_VERSION 版本應該和 Gemfile.lock 同步
current_bundler_version=$(bundle -v | awk '{print $3}')
if [ "$current_bundler_version" != "$BUNDLER_VERSION" ]; then
  set -eux; \
    gem update --system; \
    gem i bundler -v="$BUNDLER_VERSION"
else
  echo "Bundler version is already $BUNDLER_VERSION."
fi
