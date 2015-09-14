FROM ubuntu:12.04

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

# Set timezone and locale.
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Basic packages
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    curl \
    wget \
    zip \
    git \
    mysql-client \
    pv \
    apt-transport-https \
    openssh-client \
    rsync \
    iputils-ping \
    mc \
    supervisor \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adding https://launchpad.net/~ondrej/+archive/ubuntu/php5 PPA repo and it's GPG key for php5.6
RUN echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu precise main " >> /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

# PHP packages
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    php5-common \
    php5-cli \
    php-pear \
    php5-mysql \
    php5-imagick \
    php5-mcrypt \
    php5-curl \
    php5-gd \
    php5-sqlite \
    php5-json \
    php5-intl \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Drush and Drupal Console
RUN composer global require drush/drush:7.* \
    && curl -LSs http://drupalconsole.com/installer | php \
    && mv console.phar /usr/local/bin/drupal

# Add Composer bin directory to PATH
ENV PATH /root/.composer/vendor/bin:$PATH

# Drush modules
RUN drush dl registry_rebuild

## PHP settings
RUN \
    mkdir -p /var/www/docroot \
    # PHP CLI settings
    && sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php5/cli/php.ini \
    && sed -i 's/max_execution_time = .*/max_execution_time = 600/' /etc/php5/cli/php.ini \
    && sed -i '/error_log = php_errors.log/c\error_log = \/dev\/stdout/' /etc/php5/cli/php.ini

# Adding NodeJS repo (for up-to-date versions)
# This command is a stripped down version of "curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -"
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo 'deb https://deb.nodesource.com/node_0.12 wheezy main' > /etc/apt/sources.list.d/nodesource.list \
    && echo 'deb-src https://deb.nodesource.com/node_0.12 wheezy main' >> /etc/apt/sources.list.d/nodesource.list

# Other language packages and dependencies
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    ruby1.9.1-full \
    rlwrap \
    make \
    gcc \
    nodejs \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Bundler
RUN gem install bundler

# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

# Grunt, Bower
RUN npm install -g grunt-cli bower

WORKDIR /var/www

# Copy configs and scripts
COPY config/.ssh /root/.ssh
COPY config/.drush /root/.drush
COPY startup.sh /opt/startup.sh

# Set TERM so text editors/etc. can be used
ENV TERM xterm

# Default SSH key name
ENV SSH_KEY_NAME id_rsa

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD /usr/bin/supervisord -n
