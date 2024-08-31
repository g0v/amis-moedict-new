export LANG="C.UTF-8"
export RUBY_VERSION="3.3.4"
export BUNDLER_VERSION="2.5.16"
export PATH="/opt/rubies/ruby-$RUBY_VERSION/bin:$PATH"

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
      libffi-dev

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
else
  echo "Ruby version is already $RUBY_VERSION."
fi

# middle2 上是用 sh -c 執行，因此要把 * 放在字串外才能生效
if [ ! -e /usr/local/bin/gem ]; then
  set -eux; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/bundle"          /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/bundler"         /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/erb"             /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/gem"             /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/irb"             /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/racc"            /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/rake"            /usr/local/bin/; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/ruby"            /usr/local/bin/
fi

current_bundler_version=$(bundle -v | awk '{print $3}')
if [ "$current_bundler_version" != "$BUNDLER_VERSION" ]; then
  set -eux; \
    gem update --system; \
    gem i bundler -v="$BUNDLER_VERSION"; \
    gem i foreman
else
  echo "Bundler version is already $BUNDLER_VERSION."
fi

if [ ! -e /usr/local/bin/foreman ]; then
  set -eux; \
    ln -s "/opt/rubies/ruby-$RUBY_VERSION/bin/foreman" /usr/local/bin/
fi
