<?php
/**
 * Implements drush_hook_COMMAND_validate.
 *
 * Prevent a catastrophic brain-fart -- only allow users to overwrite their
 * local database.
 */
function drush_policy_sql_sync_validate($source = NULL, $dest = NULL) {
  if ($dest == '@local' || FALSE === strpos($dest, '@')) {
    return TRUE;
  }
  else {
    return drush_set_error(dt('You may only overwrite your local database -- check your source/destination order. It should be similar to "drush sql-sync @remote @local".'));
  }
}
