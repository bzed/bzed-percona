# Class: percona
# ===========================
#
# Full description of class percona here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'percona':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class percona(
    $clustername,
    $root_password,
    $debian_password,
    $clusterchk_password,
    $sst_password,
    $replication_password,
    $bind_address = $::percona::params::bind_address,
    $wsrep_node_address = $::percona::params::wsrep_node_address,
    $mysql_options = {},
    $garbd_package = $::percona::params::garbd_package,
    $garbd_fix_systemd = $::percona::params::garbd_fix_systemd,
    $mysql_package = $::percona::params::mysql_package,
    $haproxy_global_options = {},
    $haproxy_defaults_options = {},
    $haproxy_backend_options = {},
    $haproxy_socket = '/run/haproxy/admin.sock',
    $haproxy_readonly_frontend_bind  = { "${wsrep_node_address}::3307" => [] },
    $haproxy_readwrite_frontend_bind = { "${wsrep_node_address}::3308" => [] },
    $haproxy_balancermember_options = 'check port 9200 inter 12000 rise 3 fall 3 weight 100',
    $haproxy_readwrite_is_readonly_backup = false,
    $buffersize = $::percona::params::buffersize,
    $pool_instances = $::percona::params::pool_instances,
    $max_connections = $::percona::params::max_connections,
) inherits ::percona::params {


    class { '::percona::server' :
        clustername          => $clustername,
        root_password        => $root_password,
        debian_password      => $debian_password,
        replication_password => $replication_password,
        clusterchk_password  => $clusterchk_password,
        sst_password         => $sst_password,
        bind_address         => $bind_address,
        wsrep_node_address   => $wsrep_node_address,
        mysql_options        => $mysql_options,
        mysql_package        => $mysql_package,
    }

    # clusterchk
    class { '::percona::server::clustercheck' :
        user        => 'clusterchk',
        password    => $clusterchk_password,
        mysqlconfig => $::percona::params::config_file,
        require     => Class['::percona::server'],
    }

    # haproxy
    class { '::percona::server::haproxy' :
        clustername                          => $clustername,
        wsrep_node_address                   => $wsrep_node_address,
        haproxy_global_options               => $haproxy_global_options,
        haproxy_defaults_options             => $haproxy_defaults_options,
        haproxy_backend_options              => $haproxy_backend_options,
        haproxy_socket                       => $haproxy_socket,
        haproxy_readonly_frontend_bind       => $haproxy_readonly_frontend_bind,
        haproxy_readwrite_frontend_bind      => $haproxy_readwrite_frontend_bind,
        haproxy_balancermember_options       => $haproxy_balancermember_options,
        haproxy_readwrite_is_readonly_backup => $haproxy_readwrite_is_readonly_backup,
        require                              => Class['::percona::server::clustercheck'],
    }
}
