export LANG="C.UTF-8"

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
    build-essential \
    libyaml-dev \
    libffi-dev

export RUBY_VERSION="3.3.4"

set -eux; \
  git clone "https://github.com/rbenv/ruby-build.git" /tmp/ruby-build; \
  /tmp/ruby-build/bin/ruby-build "$RUBY_VERSION" "/opt/rubies/ruby-$RUBY_VERSION"

export GEM_HOME="/usr/local/etc/gemrc"
export PATH="/opt/rubies/ruby-$RUBY_VERSION/bin:$PATH"

set -eux; \
  gem update --system \
  gem i bundler -v=2.5.16
