# CLI Docker image for Drupal

[fork blinkreaction/docker-drupal-cli](https://github.com/blinkreaction/docker-drupal-cli/tree/feature/php7)


Based on Debian 7.0 "Wheezy" (debian:wheezy)

## Includes

- php
  - php-fpm && php-cli 7.1.x
  - composer 1.0-dev
  - drush 6,7,8
    - registry_rebuild
    - coder-8.x + phpcs
  - drupal console 0.9.7
- ruby
  - ruby 1.9.3
  - gem 1.8.23
  - bundler 1.10.6
- nodejs
  - nvm 0.33.4
  - nodejs 6.11.3 (via nvm)
    - npm 5.5.1
    - bower 1.6.5
- python 2.7.3

Other notable tools:

- git
- curl/wget
- zip/unzip
- mysql-client
- imagemagick
- ping
- mc

## Build image

docker-compose.yml file:

    docker-drupal-cli:
        build: docker-drupal-cli
        
run command:

    docker-compose build
    
## Use in drude

    git diff 3674986ab0fa52530fac6030cc82de37a564b0ec .drude/drude-services.yml
    diff --git a/.drude/drude-services.yml b/.drude/drude-services.yml
    index 15345772..a150b91a 100644
    --- a/.drude/drude-services.yml
    +++ b/.drude/drude-services.yml
    @@ -7,7 +7,7 @@ services:
    # Web node
    web:
        hostname: web
    -    image: blinkreaction/drupal-apache:2.2-stable
    +    image: blinkreaction/drupal-apache:2.4-stable
        volumes:
        # Project root folder mapping
        - &project_root "../:/var/www"
    @@ -26,14 +26,14 @@ services:
    # Used for all console commands and tools.
    cli:
        hostname: cli
    -    image: blinkreaction/drupal-cli:stable
    +    image: dockerdrupalcli_docker-drupal-cli:latest
        volumes:
        # Project root folder mapping
        - *project_root
        # PHP FPM configuration overrides
    -      - "./etc/php5/php.ini:/etc/php5/fpm/conf.d/z_php.ini"
    +      - ./etc/php/php.ini:/etc/php/7.1/fpm/php.ini
        # PHP CLI configuration overrides
    -      - "./etc/php5/php-cli.ini:/etc/php5/cli/conf.d/z_php.ini"
    +      - ./etc/php/php-cli.ini:/etc/php/7.1/cli/php.ini
        # Host home directory mapping (for SSH keys and ther credentials).
        # We try to map both options (b2d and Linux). The startup.sh script in cli container will decide which one to use.
        - /.home:/.home-b2d  # boot2docker-vagrant

## License

The MIT License (MIT)

Copyright (c) 2015 blinkreaction

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
