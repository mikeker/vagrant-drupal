{% if grains['os'] == 'Ubuntu' %}
{% set HOME='/home/vagrant' %}

# Server utils
libcurl4-openssl-dev:
  pkg:
    - installed
libcurl3:
  pkg:
    - installed
libpcre3-dev:
  pkg:
    - installed
force curl install:
  # Don't know why this isn't part of the precise64 box...?
  cmd.run:
    - name: apt-get install curl
    - unless: curl --version

# Database
mysql:
  pkg.installed:
    - name: mysql-server
  service.running:
    - enable: True
    - require:
      - pkg: mysql-server

python-mysqldb:
  # We'll need this for later DB related things in Salt.
  pkg:
    - installed
    - require:
      - pkg: mysql-server

# Web server
apache2:
  pkg:
    - installed

apache site conf:
  file.managed:
    - name: /etc/apache2/sites-available/bef.d7.conf
    - source: salt://drupal/files/bef.d7.conf
    - user: vagrant
    - group: vagrant
    - mode: 0644
    - require:
      - pkg: apache2

enable site:
  cmd.run:
    # @TODO: Need to generalize this into some sort of imported config file.
    - name: a2ensite bef.d7.conf
    - unless: test -L /etc/apache2/sites-enabled/bef.d7.conf
    - require:
      - file: apache site conf

enable rewrite:
  cmd.run:
    - name: a2enmod rewrite
    - unless: test -L /etc/apache2/mods-enabled/rewrite.load
    - require:
      - pkg: apache2

disable cgi:
  cmd.run:
    - name: a2dismod cgi
    - unless: test ! -L /etc/apache2/mods-enabled/cgi.load
    - require:
      - pkg: apache2

start apache2:
  cmd.run:
    - name: service apache2 restart
    - watch:
      - cmd: enable site
      - cmd: enable rewrite
      - cmd: disable cgi

# apache.configfile:
#   - name: /etc/apache2/sites-available/local.core.d8
#   - require:
#     - pkg: apache2
#   - config:
#     - VirtualHost:
#         this: '*:80'
#         ServerName:
#           - local.core.d8
#         # ServerAlias:
#         #   - www.website.com
#         #   - dev.website.com
#         ErrorLog: logs/core.d8-error_log
#         CustomLog: logs/core.d8-access_log combined
#         DocumentRoot: /var/www/d8
#         Directory:
#           this: /var/www/d8
#           Order: Deny,Allow
#           Deny from: all
#           Allow from:
#             - 127.0.0.1
#             - 192.168.33.10
#           Options:
#             - +Indexes
#             - FollowSymlinks
#           AllowOverride: All

#
# Latest PHP (5.3 on Precise)
#
#php5:
#  pkg:
#  - installed
#  - require:
#    - pkg: apache2

#
# PHP 5.5 from repo.
#
php5_ppa:
  pkgrepo.managed:
    - ppa: ondrej/php5
php5:
  pkg.latest:
    - refresh: True
    - require:
      - pkgrepo: php5_ppa
  service.running:
    - enable: True
    - require:
      - pkg: php5
      - pkg: php5-curl
      - pkg: php5-mysql
      - pkg: php5-cli

# PHP 5.x modules
php5-cli:
  pkg:
  - installed
  - require:
    - pkg: php5
php5-gd:
  pkg:
  - installed
  - require:
    - pkg: php5
php5-mysql:
  pkg:
  - installed
  - require:
    - pkg: php5
php5-curl:
  pkg:
  - installed
  - require:
    - pkg: php5

# Tweak some php.ini settings
/etc/php5/apache2/php.ini:
  file.append:
    - text: |
        [PHP]
        memory_limit = 256M
        realpath_cache_size = 16M
        realpath_cache_ttl = 60
        opcache.revalidate_freq = 0
        opcache.validate_timestamps = 0
        opcache.max_accelerated_files = 8000
        opcache.memory_consumption = 192
        opcache.interned_strings_buffer = 16
        opcache.fast_shutdown = 1
restart apache2:
  cmd.run:
    - name: service apache2 restart
    - watch:
      - file: /etc/php5/apache2/php.ini

# Version control
git:
  pkg:
    - installed

# Misc server tweaks
common_aliases:
  file.managed:
  - name: {{ HOME }}/.bash_aliases
  - user: vagrant
  - source: salt://drupal/files/bash_aliases
  - node: 2444


#
# Drupal specific stuff
#

# Install Drush via Composer
#   Composer first
get-composer:
  cmd.run:
    - name: 'CURL=`which curl`; $CURL -sS https://getcomposer.org/installer | php'
    - unless: test -f /usr/local/bin/composer
    - cwd: /home/vagrant/

install-composer:
  cmd.wait:
    - name: mv /home/vagrant/composer.phar /usr/local/bin/composer
    - cwd: /home/vagrant/
    - watch:
      - cmd: get-composer

# Install Drush via Composer and symlink so it's on the global path
install drush:
  cmd.run:
    - name: composer global require drush/drush:dev-master --prefer-source
    - cwd: /home/vagrant/
    - unless: drush status

/usr/local/bin/drush:
  file.symlink:
    - target: /home/vagrant/.composer/vendor/drush/drush/drush
    - require:
      - cmd: install drush

drush config dir:
  file.directory:
     - name: {{ HOME }}/.drush
     - user: vagrant
     - group: vagrant
     - mode: 0755

drush cache dir:
  file.directory:
    - name: {{ HOME }}/.drush/cache
    - user: vagrant
    - group: vagrant
    - mode: 0755
    - require:
      - file: drush config dir

drush aliases:
  file.managed:
     - name: {{ HOME }}/.drush/aliases.drushrc.php
     - source: salt://drupal/files/drushrc.php
     - user: vagrant
     - group: vagrant
     - mode: 0644
     - require:
       - file: drush config dir

drush policy:
  file.managed:
     - name: {{ HOME }}/.drush/policy.drush.inc
     - source: salt://drupal/files/policy.drush.inc
     - user: vagrant
     - group: vagrant
     - mode: 0644
     - require:
       - file: drush aliases


# Setup a MySQL DB and user for Drupal
# ... clearly this is for dev work only as the user password is not secure.
drupal_db:
  mysql_database.present:
    - names:
      - drupaldb
    - require:
      - pkg: mysql-server
      - pkg: python-mysqldb

drupal_db_user:
  mysql_user.present:
    - host: localhost
    - name: drupal
    - password: drupal
  mysql_grants.present:
    # based upon https://drupal.org/documentation/install/create-database
    - host: localhost
    - user: drupal

    # NOTE: The ordering of the elements in the grant DOES matter; the salt
    # module will re-query, and the order that the DB returns must match this
    # order.
    - grant: SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES

    - database: drupaldb.*
    - require:
      - mysql_database: drupal_db

{% endif %}
