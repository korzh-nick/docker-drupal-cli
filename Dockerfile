FROM blinkreaction/drupal-base:jessie

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

# Basic packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    zip unzip \
    git \
    mysql-client \
    imagemagick \
    pv \
    openssh-client \
    openssh-server \
    rsync \
    apt-transport-https \
    ca-certificates \
    sudo \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
    # Create a non-root user with access to sudo and the default group set to 'users' (gid = 100)
    useradd -m -s /bin/bash -g users -G sudo -p docker docker && \
    echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Configure sshd (for use PHPStorm's remote interpreters and tools integrations)
# http://docs.docker.com/examples/running_ssh_service/
RUN mkdir /var/run/sshd & \
    echo 'docker:docker' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # SSH login fix. Otherwise user is kicked off after login
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile
ENV NOTVISIBLE "in users profile"

# Add Dotdeb PHP7.0 repo
# RUN echo 'deb http://packages.dotdeb.org jessie all' >> /etc/apt/sources.list && \
#     echo 'deb-src http://packages.dotdeb.org jessie all' >> /etc/apt/sources.list && \
#     # Dotdeb repo key
#     wget http://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg && rm -f dotdeb.gpg

# Add sury.org PHP7.1 repo
RUN  echo 'deb https://packages.sury.org/php/ jessie main' >> /etc/apt/sources.list && \
    wget https://packages.sury.org/php/apt.gpg && apt-key add apt.gpg && rm -f apt.gpg

# PHP packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    php7.1-common \
    php7.1-cli \
    php-pear \
    php7.1-mysql \
    php7.1-imagick \
    php7.1-mcrypt \
    php7.1-curl \
    php7.1-gd \
    php7.1-sqlite3 \
    php7.1-json \
    php7.1-intl \
    php7.1-fpm \
    php7.1-memcache \
    php7.1-xdebug \
    php7.1-opcache \
    php7.1-mbstring \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## PHP settings
RUN mkdir -p /var/www/docroot && \
    # PHP-FPM settings
    ## /etc/php/7.1/fpm/php.ini
    sed -i '/memory_limit = /c memory_limit = 256M' /etc/php/7.1/fpm/php.ini && \
    sed -i '/max_execution_time = /c max_execution_time = 300' /etc/php/7.1/fpm/php.ini && \
    sed -i '/upload_max_filesize = /c upload_max_filesize = 500M' /etc/php/7.1/fpm/php.ini && \
    sed -i '/post_max_size = /c post_max_size = 500M' /etc/php/7.1/fpm/php.ini && \
    sed -i '/error_log = /c error_log = \/dev\/stdout' /etc/php/7.1/fpm/php.ini && \
    sed -i '/;always_populate_raw_post_data/c always_populate_raw_post_data = -1' /etc/php/7.1/fpm/php.ini && \
    sed -i '/;sendmail_path/c sendmail_path = /bin/true' /etc/php/7.1/fpm/php.ini && \
    ## /etc/php/7.1/fpm/pool.d/www.conf
    sed -i '/user = /c user = docker' /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i '/;catch_workers_output = /c catch_workers_output = yes' /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i '/listen = /c listen = 0.0.0.0:9000' /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i '/listen.allowed_clients/c ;listen.allowed_clients =' /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i '/;clear_env = /c clear_env = no' /etc/php/7.1/fpm/pool.d/www.conf && \
    ## /etc/php/7.1/fpm/php-fpm.conf
    sed -i '/;daemonize = /c daemonize = no' /etc/php/7.1/fpm/php-fpm.conf && \
    sed -i '/error_log = /c error_log = \/dev\/stdout' /etc/php/7.1/fpm/php-fpm.conf && \
    sed -i '/pid = /c pid = \/run\/php-fpm7.1.pid' /etc/php/7.1/fpm/php-fpm.conf && \
    # PHP CLI settings
    sed -i '/memory_limit = /c memory_limit = 512M' /etc/php/7.1/cli/php.ini && \
    sed -i '/max_execution_time = /c max_execution_time = 600' /etc/php/7.1/cli/php.ini && \
    sed -i '/error_log = php_errors.log/c error_log = \/dev\/stdout' /etc/php/7.1/cli/php.ini && \
    sed -i '/;sendmail_path/c sendmail_path = /bin/true' /etc/php/7.1/cli/php.ini && \
    # Make xdebug available for php-fpm only
    rm  /etc/php/7.1/cli/conf.d/20-xdebug.ini && \
    # PHP module settings
    echo 'opcache.memory_consumption=128' >> /etc/php/7.1/mods-available/opcache.ini

COPY config/php/xdebug.ini /etc/php/7.1/mods-available/xdebug.ini

# Adding NodeJS repo (for up-to-date versions)
# This is a stripped down version of the official nodejs install script (https://deb.nodesource.com/setup_4.x)
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_4.x jessie main' >> /etc/apt/sources.list.d/nodesource.list

# Other language packages and dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    ruby-full \
    rlwrap \
    build-essential \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# bundler
RUN gem install bundler
# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

ENV DRUSH_VERSION 8.1.15
ENV DRUPAL_CONSOLE_VERSION 1.0.2

RUN \
    # Composer
    curl -sSL https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    # Drush 8 (default)
    curl -sSL https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar -o /usr/local/bin/drush && \
    chmod +x /usr/local/bin/drush && \
    # Drupal Console
    curl -sSL https://github.com/hechoendrupal/DrupalConsole/releases/download/$DRUPAL_CONSOLE_VERSION/drupal.phar -o /usr/local/bin/drupal && \
    chmod +x /usr/local/bin/drupal

# All further RUN commands will run as the "docker" user
USER docker
ENV HOME /home/docker

# Install nvm and a default node version
ENV NVM_VERSION=0.33.4 \
	NODE_VERSION=6.11.3 \
	NVM_DIR=$HOME/.nvm
RUN \
    curl -sSL https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    # Install global node packages
    npm install -g npm && \
	# Cleanup
	nvm clear-cache && npm cache clear --force && \
	# Fix npm complaining about permissions and not being able to update
        sudo rm -rf $HOME/.config

ENV PATH $PATH:$HOME/.composer/vendor/bin
RUN \
    # Add composer bin directory to PATH
    echo "\n"'PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile && \
    # Legacy Drush versions (6 and 7)
    mkdir $HOME/drush6 && cd $HOME/drush6 && composer require drush/drush:6.* && \
    mkdir $HOME/drush7 && cd $HOME/drush7 && composer require drush/drush:7.* && \
    echo "alias drush6='$HOME/drush6/vendor/bin/drush'" >> $HOME/.bashrc && \
    echo "alias drush7='$HOME/drush7/vendor/bin/drush'" >> $HOME/.bashrc && \
    echo "alias drush8='/usr/local/bin/drush'" >> $HOME/.bashrc && \
    # Drush modules
    drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush && \
    drush cc drush && \
    # Drupal Coder w/ a matching version of PHP_CodeSniffer
    composer global require drupal/coder && \
    phpcs --config-set installed_paths $HOME/.composer/vendor/drupal/coder/coder_sniffer

# Copy configs and scripts
COPY config/.ssh $HOME/.ssh
COPY config/.drush $HOME/.drush
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh

# Fix permissions after COPY
RUN sudo chown -R docker:users $HOME

EXPOSE 9000
EXPOSE 22

WORKDIR /var/www

# Default SSH key name
ENV SSH_KEY_NAME id_rsa

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD ["gosu", "root", "supervisord"]
