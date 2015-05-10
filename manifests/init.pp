# = Class: transmission
# 
# This class installs/configures/manages the transmission-daemon bittorrent client.
#
# == Sample Usage:
#
#  class {'transmission':
#    download_dir   => "/downloads",
#    incomplete_dir => "/tmp/downloads",
#    web_port       => 9091,
#    web_whitelist  => ['127.0.0.1'],
#    blocklist_url  => 'http://list.iblocklist.com/?list=bt_level1',
#  }
#
# See params.pp for a full list of parameters.

class transmission (
  $config_path                  = $transmission::params::config_path,
  $download_dir                 = $transmission::params::download_dir,
  $incomplete_dir               = $transmission::params::incomplete_dir,
  $blocklist_url                = $transmission::params::blocklist_url,
  $web_port                     = $transmission::params::web_port,
  $web_user                     = $transmission::params::web_user,
  $web_password                 = $transmission::params::web_password,
  $web_whitelist                = $transmission::params::web_whitelist,
  $package_name                 = $transmission::params::package_name,
  $transmission_user            = $transmission::params::transmission_user,
  $transmission_group           = $transmission::params::transmission_group,
  $service_name                 = $transmission::params::service_name,
  $umask                        = $transmission::params::umask,
  $ratio_limit                  = $transmission::params::ratio_limit,
  $peer_port                    = $transmission::params::peer_port,
  $speed_down                   = $transmission::params::speed_down,
  $speed_up                     = $transmission::params::speed_up,
  $seed_queue_enabled           = $transmission::params::seed_queue_enabled,
  $seed_queue_size              = $transmission::params::seed_queue_size,
  $script_torrent_done_enabled  = $transmission::params::seed_torrent_done_enabled,
  $script_torrent_done_filename = $transmission::params::seed_torrent_done_filename,
) inherits transmission::params {

  $_settings_json = "${config_path}/settings.json"
  
  $settings_tmp = '/tmp/transmission-settings.tmp'
  
  package { 'transmission-daemon':
    name   => $package_name,
    ensure => installed,
  }

  # Find out the name of the transmission user/group
  # ## // Moved to calling class //

  # Transmission should be able to read the config dir
  file { $config_path:
    ensure   => directory,
    group    => $transmission_group,            # We only set the group (the dir could be owned by root or someone ele)
    mode     => 'g+rx',                         # Make sure transmission can access the config dir
    require  => Package['transmission-daemon'], # Make sure that the package is installed and had the opportunity to create the directory first
  }

  # The settings file should follow our template
  file { 'settings.json':
    path    => $_settings_json,
    ensure  => file,
    content => template("${module_name}/settings.json.erb"),
    mode    => 'u+rw',          # Make sure transmisson can r/w settings
    owner   => $transmission_user,
    group   => $transmission_group,
    require => [Package['transmission-daemon'],File[$config_path]],
    notify  => Exec['activate-new-settings'],
  }

  # Helper. To circumvent transmission's bad habit of rewriting 'settings.json' every now and then.
  exec { 'activate-new-settings':
    refreshonly => true,        # Run only when another resource (File['settings.json']) tells us to do it
    command     => "cp $_settings_json $settings_tmp; service $service_name stop; sleep 5; cat $settings_tmp > $_settings_json; chmod u+r $_settings_json",
    path        => ['/bin','/sbin', '/usr/sbin'],
    notify      => Service['transmission-daemon'], # Now we can tell the service about the changes // Start service
  }


  # Transmission should use the settings in ${config_path}/settings.json *only*
  # This is ugly, but necessary
  file {['/etc/default/transmission','/etc/sysconfig/transmission']:
    ensure  => absent,                         # Kill the bastards
    require => Package['transmission-daemon'], # The package has to be installed first. Otherwise this would be sheer folly.
    before  => Service['transmission-daemon'], # After this is fixed, we can handle the service
  }
    
  # Manage the download directory.  Creating parents will be taken care of "upstream" (in the calling class)
  file { $download_dir:
    ensure  => directory,
    #recurse => true,  # Broken. Creates invalid resurce tags for some downloaded files with funny characters.
    owner   => $transmission_user,
    group   => $transmission_group,
    mode    => 'ug+rw,u+x',
    require => Package['transmission-daemon'], # Let's give the installer a chance to create the directory and user before we manage this dir
  }

  # directory for partial downloads
  if $incomplete_dir {
    file { $incomplete_dir:
      ensure  => directory,
      recurse => true,
      owner   => $transmission_user,
      group   => $transmission_group,
      mode    => 'ug+rw,u+x',
      require => Package['transmission-daemon'],
    }
  }

  # Keep the service running
  service { 'transmission-daemon':
    name       => $service_name,
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['transmission-daemon'],
  }

  # Keep blocklist updated
  if $blocklist_url {
    if $web_password {
      $opt_auth = " --auth ${web_user}:${web_password}"
    }
    else
    {
      $opt_auth = ""
    }
    cron { 'update-blocklist':
      command => "/usr/bin/transmission-remote http://127.0.0.1:${web_port}/transmission/${opt_auth} --blocklist-update 2>&1 > /tmp/blocklist.log",
      user    => root,
      hour    => 2,
      minute  => 0,
      require => Package['transmission-daemon'],
    }
  }
}
