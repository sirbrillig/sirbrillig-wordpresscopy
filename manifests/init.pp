# == Class: wordpresscopy
#
# Using two files, a tar of an existing WordPress install directory and a sql
# file of the site's database (generated by mysqldump), re-create the WordPress
# site.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { wordpresscopy:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Payton Swick <payton@foolord.com>
#
# === Copyright
#
# Copyright 2013 Payton Swick
#
class wordpresscopy (
  $wp_site_file = 'wordpress.tar.gz',
  $wp_db_dump = 'wordpress.mysql',
  $new_site_host = 'localhost',
  $install_dir = '/opt/wordpress',
  $wp_owner = 'www-data',
  $wp_group = 'www-data',
  $db_name = 'wordpress',
  $db_host = 'localhost',
  $db_user = 'wordpress',
  $db_password = 'password',
) {
  validate_string($install_dir,$wp_site_file,$wp_db_dump,$new_site_host,$wp_owner,$wp_group,$db_name,$db_host,$db_user,$db_password)

  File {
    owner  => $wp_owner,
    group  => $wp_group,
    mode   => '0644',
  }

  Exec {
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    cwd       => $install_dir,
  }

  Database {
      require => Class['mysql::server'],
  }

  file { "${install_dir}":
    ensure => 'directory',
  }

  exec { 'extract wordpress':
    command => "tar xzvf ${wp_site_file} -C ${install_dir} --strip-components 1",
    creates => "${install_dir}/index.php",
    require => File["${install_dir}"],
  }

  database { "${db_name}":
    ensure => 'present',
    charset => 'utf8',
  }

  database_user { "${db_user}@localhost":
    password_hash => mysql_password($db_password),
  }

  database_grant { "${db_user}@localhost/${db_name}":
    privileges => ['all'],
  }

  exec { 'import database':
    unless => "test -z 'mysql -u${db_user} -p${db_password} ${db_name} -e \"show tables\"'", # FIXME: Not sure this is working!
    command => "mysql -u${db_user} -p${db_password} ${db_name} < ${wp_db_dump}",
    require => Database["${db_name}"],
  }
}
