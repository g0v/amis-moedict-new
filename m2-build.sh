# ref https://github.com/docker-library/ruby/blob/2e432fc966a291fa241b14637557710d33a05b42/3.3/bullseye/Dockerfile

# skip installing gem documentation
set -eux; \
  mkdir -p /usr/local/etc; \
  { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

export LANG="C.UTF-8"

# https://www.ruby-lang.org/en/news/2024/07/09/ruby-3-3-4-released/
export RUBY_VERSION="3.3.4"
export RUBY_DOWNLOAD_URL="https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.4.tar.xz"
export RUBY_DOWNLOAD_SHA256="1caaee9a5a6befef54bab67da68ace8d985e4fb59cd17ce23c28d9ab04f4ddad"

set -eux; \
  \
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    autoconf \
    dpkg-dev \
    libgdbm-dev \
    ruby \
  ; \
  rm -rf /var/lib/apt/lists/*; \
  \
  rustArch=; \
  dpkgArch="$(dpkg --print-architecture)"; \
  case "$dpkgArch" in \
    'amd64') rustArch='x86_64-unknown-linux-gnu'; rustupUrl='https://static.rust-lang.org/rustup/archive/1.26.0/x86_64-unknown-linux-gnu/rustup-init'; rustupSha256='0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db' ;; \
    'arm64') rustArch='aarch64-unknown-linux-gnu'; rustupUrl='https://static.rust-lang.org/rustup/archive/1.26.0/aarch64-unknown-linux-gnu/rustup-init'; rustupSha256='673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800' ;; \
  esac; \
  \
  if [ -n "$rustArch" ]; then \
    mkdir -p /tmp/rust; \
    \
    curl -o /tmp/rust/rustup-init "$rustupUrl"; \
    echo "$rustupSha256 */tmp/rust/rustup-init" | sha256sum --check --strict; \
    chmod +x /tmp/rust/rustup-init; \
    \
    export RUSTUP_HOME='/tmp/rust/rustup' CARGO_HOME='/tmp/rust/cargo'; \
    export PATH="$CARGO_HOME/bin:$PATH"; \
    /tmp/rust/rustup-init -y --no-modify-path --profile minimal --default-toolchain '1.74.1' --default-host "$rustArch"; \
    \
    rustc --version; \
    cargo --version; \
  fi; \
  \
  curl -o ruby.tar.xz "$RUBY_DOWNLOAD_URL"; \
  echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; \
  \
  mkdir -p /usr/src/ruby; \
  tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1; \
  rm ruby.tar.xz; \
  \
  cd /usr/src/ruby; \
  \
  { \
    echo '#define ENABLE_PATH_CHECK 0'; \
    echo; \
    cat file.c; \
  } > file.c.new; \
  mv file.c.new file.c; \
  \
  autoconf; \
  gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
  ./configure \
    --build="$gnuArch" \
    --disable-install-doc \
    --enable-shared \
    ${rustArch:+--enable-yjit} \
  ; \
  make -j "$(nproc)"; \
  make install; \
  \
  rm -rf /tmp/rust; \
  apt-mark auto '.*' > /dev/null; \
  apt-mark manual $savedAptMark > /dev/null; \
  find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
  ; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  \
  cd /; \
  rm -r /usr/src/ruby; \
  [ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; \
  ruby --version; \
  gem --version; \
  bundle --version

export GEM_HOME="/usr/local/bundle"
export BUNDLE_SILENCE_ROOT_WARNING=1 \
       BUNDLE_APP_CONFIG="$GEM_HOME"
export PATH="$GEM_HOME/bin:$PATH"
set -eux; \
  mkdir "$GEM_HOME"; \
  chmod 1777 "$GEM_HOME"
