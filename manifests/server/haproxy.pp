# Setup HAProxy

class percona::server::haproxy(
  $clustername,
  $wsrep_node_address,
  $haproxy_global_options = {},
  $haproxy_defaults_options = {},
  $haproxy_backend_options = {},
  $haproxy_socket = '/run/haproxy/admin.sock',
  $haproxy_readonly_frontend_bind  = { "${wsrep_node_address}:3307" => [] },
  $haproxy_readwrite_frontend_bind = { "${wsrep_node_address}:3308" => [] },
  $haproxy_balancermember_options = 'check port 9200 inter 12000 rise 3 fall 3 weight 100',
  $haproxy_readwrite_is_readonly_backup = false,
){

  if $::osfamily == 'Debian' {
    ensure_packages('hatop')
  }

  $clusternodes = getvar("::percona_cluster_${clustername}")
  if $clusternodes {
    $clusternodes_array = split($clusternodes, ',')
  } else {
    $clusternodes_array = undef
  }

  if ($clusternodes_array
  and $wsrep_node_address
  and !empty($clusternodes_array)
  and $clusternodes_array[0] == $wsrep_node_address
  ) {
    $rw_backend = true
  } else {
    $rw_backend = false
  }


  $haproxy_default_global_options = {
    'log'      => [
      '/var/lib/haproxy/dev/log local0',
    ],
    'chroot'   => '/var/lib/haproxy',
    'stats'    => "socket ${haproxy_socket} level admin mode 0660",
    'user'     => 'haproxy',
    'group'    => 'haproxy',
    'ulimit-n' => '65536',
    'maxconn'  => '32000',
  }

  $haproxy_default_defaults_options = {
    'log'     => 'global',
    'mode'    => 'http',
    'timeout' => [
      'connect 5s',
      'client 28800s',
      'server 28800s',
    ],
    'option'  => [
      'log-health-checks',
      'dontlognull',
      'dontlog-normal',
      'tcplog',
      'redispatch',
    ],
    'retries' => 3,
    'maxconn' => '32000',
  }

  $haproxy_default_backend_options = {
    'mode'      => 'tcp',
    'balance'   => 'leastconn',
    option      => [
      'tcplog',
      'httpchk',
    ],
    'fullconn' => '2048',
  }

  class { '::haproxy' :
    global_options   => deep_merge(
      $haproxy_default_global_options,
      $haproxy_global_options
    ),
    defaults_options => deep_merge(
      $haproxy_default_defaults_options,
      $haproxy_defaults_options
    ),
    restart_command  => '/bin/true',
  }


  Haproxy::Backend{
    options => deep_merge(
      $haproxy_default_backend_options,
      $haproxy_backend_options
    ),
    collect_exported => false,
    require          => Service['clustercheck.socket'],
  }

  ::haproxy::frontend{"${clustername}-ro":
    bind    => $haproxy_readonly_frontend_bind,
    mode    => 'tcp',
    options => {
      'option'          => [
        'log-health-checks',
        'dontlognull',
        'dontlog-normal',
        'tcplog',
      ],
      'default_backend' => "${clustername}-ro",
    },
  }

  ::haproxy::frontend{"${clustername}-rw":
    bind    => $haproxy_readwrite_frontend_bind,
    mode    => 'tcp',
    options => {
      'option'          => [
        'tcplog',
      ],
      'default_backend' => "${clustername}-rw",
    },
  }

  ::haproxy::backend{"${clustername}-ro":
  }
  ::haproxy::backend{"${clustername}-rw":
  }

  Haproxy::Balancermember<<| listening_service == "${clustername}-ro" and tag == 'bzed-percona_cluster' |>>
  Haproxy::Balancermember<<| listening_service == "${clustername}-rw" and tag == 'bzed-percona_cluster' |>>

  if $haproxy_readwrite_is_readonly_backup and $rw_backend {
    $ro_backup = ' backup'
  } else {
    $ro_backup = ''
  }

  @@::haproxy::balancermember{"${::hostname}-ro":
    listening_service => "${clustername}-ro",
    ports             => 3306,
    ipaddresses       => $wsrep_node_address,
    server_names      => $::hostname,
    options           => "${haproxy_balancermember_options}${ro_backup}",
    tag               => 'bzed-percona_cluster',
  }

  if $rw_backend {
    #lint:ignore:empty_string_assignment
    $rw_backup = ''
    #lint:endignore
  } else {
    $rw_backup = ' backup'
  }

  @@::haproxy::balancermember{"${::hostname}-rw":
    listening_service => "${clustername}-rw",
    ports             => 3306,
    ipaddresses       => $wsrep_node_address,
    server_names      => $::hostname,
    options           => "${haproxy_balancermember_options}${rw_backup}",
    tag               => 'bzed-percona_cluster',
  }


}
