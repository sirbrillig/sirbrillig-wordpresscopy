group { "puppet":
  ensure => "present",
}

File { owner => 0, group => 0, mode => 0644 }
file { '/etc/motd':
  content => "Welcome to your Vagrant-built virtual machine! Managed by Puppet.\n"
}

class ntp {
  package {
    "ntp": 
    ensure => installed
  }

  service { "ntp":
    ensure => running,
  }
}

class { 'vim': }

class { 'mysql': }
class { 'mysql::server': }

class { 'wordpresscopy': 
  wp_site_file => '/vagrant/wordpress.tar.gz',
  wp_db_dump => '/vagrant/wordpress.mysql',
  db_name => 'wordpress',
  db_user => 'wordpress',
  db_password => 'password',
  old_site_host => 'oldsite.foo.com',
  new_site_host => 'newsite.foo.com',
}

class { 'apache': }
class { 'apache::mod::php': }
package { 'php5-gd': 
  ensure => 'present',
} 
package { 'php5-curl': 
  ensure => 'present',
} 
class { 'mysql::php': }
apache::vhost { 'newsite.foo.com':
  priority        => '10',
  vhost_name      => '*',
  port            => '80',
  docroot         => '/opt/wordpress/',
  override        => 'all',
}
