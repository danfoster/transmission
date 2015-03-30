# - Class: transmission::params
#
# Default Parameter values
#
# == Parameters: 
#
# [*download_dir*]
#   The directory where the files have to be downloaded. Defaults to
#   +$config_path/downloads+.
#
# [*incomplete_dir*]
#   The temporary directory used to store incomplete files. Disabled when the
#   option is not set (this is the default).
#
# [*web_port*]
#   The port the web server is listening on. Defaults to +9091+.
#
# [*web_user*]
#   The web client login name. Defaults to +transmission+.
#
# [*web_password*]
#   The password of the web client user (default: <none>).
#
# [*web_whitelist*]
#   An array of IP addresses. This list define which machines are allowed to
#   use the web interface. It is possible to use wildcards in the addresses. By
#   default the list is empty.
#
# [*blocklist_url*]
#   An url to a block list (default: <none>).
#
# [*package_name*]
#   Name of the package. Default to 'transmission-daemon'.
#
# [*transmission_user*]
#   Default 'transmission'.
#
# [*transmission_group*]
#   Default 'transmission'.
#
# [*service_name*]
#   Default = $package_name.
#
# [*script_torrent_done_enabled*]
#   Run a script at torrent completion (default: false).
#
# [*script_torrent_done_filename*]
#   Path to script to run on torrent completion (default: "").

class transmission::params {
  $config_path                  = undef
  $download_dir                 = '/downloads'
  $incomplete_dir               = undef
  $blocklist_url                = undef
  $web_port                     = 9091
  $web_user                     = 'transmission'
  $web_password                 = undef
  $web_whitelist                = []
  $package_name                 = 'transmission-daemon'
  $transmission_user            = 'transmission'
  $transmission_group           = 'transmission'
  $service_name                 = $package_name
  $umask                        = 18 # Umask for downloaded files (in decimal)
  $ratio_limit                  = undef # No ratio limit
  $peer_port                    = 61500 #
  $speed_down                   = undef # undef=Unlimited
  $speed_up                     = undef # undef=Unlimited
  $seed_queue_enabled           = true
  $seed_queue_size              = 10
  $script_torrent_done_enabled  = false
  $script_torrent_done_filename = ""
}
