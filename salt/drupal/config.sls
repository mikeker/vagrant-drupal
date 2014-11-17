# You can run this state as a one time instance by issuing the following command
# on the destination box
#
# sudo salt-call state.sls drupal.config
#
# optional:
# --log-level=debug

include:
  - drupal

# initialize_website:
#   cmd.run:
#     - name: /bin/sh postinst.in configure
#     - cwd: /var/www/d8
#     - user: root
#     - require:
#       - file: drush_policy_config
