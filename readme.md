# Readme

Add this to your docker-compose.yml:

	XDEBUG_CONFIG: remote_host=host.docker.internal

## Some notes

- Composer has to be version 1 to work correctly with Drupal 8.
- The database used here as default is 'une' and not 'unedev' as in the Vagrant config.
