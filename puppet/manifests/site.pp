## General Settings ##

Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/', '/usr/local/bin/', '/usr/local/sbin/' ] }

## Class Definitions ##

class postgis {
  $user = 'gisuser'
  $db = 'poidatabase'

  $packages = ["postgresql-contrib", "postgis", "postgresql-9.3-postgis-2.1"]

  class { 'postgresql':
    version => '9.3',
    config_file_hba => '/etc/postgresql/9.3/main/pg_hba.conf',
    source_hba => '/vagrant/puppet/files/fiware-poi/pg_hba.conf'
  }
  ->
  package { $packages: ensure => installed }
  ->
  postgresql::role { $user: }
  ->
  postgresql::db { 'poidatabase': 
    owner => $user,
    encoding => 'UTF8',
  }
  ->
  exec { "pg_en_gis":
    command => "sudo -u postgres psql -d poidatabase -f /usr/share/postgresql/9.3/contrib/postgis-2.1/postgis.sql",
  }
  ->
  exec { "pg_en_spatial":
    command => "sudo -u postgres psql -d poidatabase -f /usr/share/postgresql/9.3/contrib/postgis-2.1/spatial_ref_sys.sql",
  }
  ->
  exec { "pg_en_gis_comment":
    command => "sudo -u postgres psql -d poidatabase -f /usr/share/postgresql/9.3/contrib/postgis-2.1/postgis_comments.sql",
  }
  ->
  exec { "pg_en_spatial_ref":
    command => "sudo -u postgres psql -d poidatabase -c \"GRANT SELECT ON spatial_ref_sys TO PUBLIC;\"",
  }
  ->
  exec { "pg_en_geom_col":
    command => "sudo -u postgres psql -d poidatabase -c \"grant all on geometry_columns to gisuser;\"",
  }
  ->
  exec { "pg_en_uuid":
    command => "sudo -u postgres psql -d poidatabase -c 'create extension IF NOT EXISTS \"uuid-ossp\";'",
  }
}

class mongodb {
  class {'::mongodb::globals':
    bind_ip             => ["127.0.0.1"],
  }
  ->
  class {'::mongodb::server':
    port    => 27017,
    verbose => true,
    ensure  => "present"
  }
  ->
  class {'::mongodb::client': }
}

class fiware-poi {
  package { [
      'git'
    ]:
    ensure => 'installed',
  }

  exec { 'fiware-poi-clone':
    command => 'git clone https://github.com/Chiru/FIWARE-POIDataProvider.git /var/www/fiware-poi',
    creates => '/var/www/fiware-poi',
    require => Package['git']
  }
  ->
  exec { 'fiware-poi-checkout-v3.3':
    command => 'git checkout 6796d314b818bf06a97fbc87a27b175fcf620665',
    cwd => '/var/www/fiware-poi',
    unless => 'git status | grep -q "HEAD detached at 6796d31"'
  }

  exec { 'fiware-poi-install':
    command => '/var/www/fiware-poi/install_scripts/create_tables.sh',
    cwd => '/var/www/fiware-poi/install_scripts',
    unless => 'echo "\dt" | psql -U gisuser -d poidatabase | grep -q "| fw_core"',
    require => [Exec['fiware-poi-clone'], Class['postgis'], Class['mongodb']]
  }
  
  file { 'fieware-poi-composer.json':
    path => '/var/www/fiware-poi/php/composer.json',
    source => '/vagrant/puppet/files/fiware-poi/composer.json',
    replace => "no",
    ensure  => "present",
    mode => 644,
    require => Exec['fiware-poi-clone']
  }

  exec { 'fiware-poi-composer-install':
    command => 'composer install',
    cwd => '/var/www/fiware-poi/php',
    creates => '/var/www/fiware-poi/php/vendor',
    environment => 'HOME=/root',
    require => [Class['composer'], File['fieware-poi-composer.json']]
  }

  apache::module { 'rewrite': }
  ->
  apache::module { 'headers': }
  ->
  file { '000_default':
    path => '/etc/apache2/sites-enabled/000-default.conf',
    ensure  => "absent"
  }
  ->
  apache::vhost { 'default':
    source      => '/vagrant/puppet/files/fiware-poi/default.conf',
    template    => '',
    require     => File['000_default']
  }
}

## Execute Tasks ##

class { 'apache':
  service_autorestart => 'yes'
}
class { 'php': }
php::pecl::module { "mongo": }
php::module { "pgsql": }
class { 'postgis': }
class { 'mongodb': }
class { 'composer': }
class { 'fiware-poi': }


