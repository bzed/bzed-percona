# Install Percona

class percona::server(
    $clustername,
    $root_password,
    $debian_password,
    $replication_password,
    $clusterchk_password,
    $sst_password,
    $bind_address = $::ipaddress,
    $wsrep_node_address = $::ipaddress,
    $mysql_options = {},
    $mysql_package = 'percona-xtradb-cluster-56',
    $mysql_service_manage = false,
    $mysql_service_enable = false,
) {

    require ::percona::server::config
    $default_options = $::percona::server::config::default_options

    ::percona::server::nodes::export { $wsrep_node_address :
        clustername => $clustername,
    }

    class { '::percona::server::nodes' :
        clustername => $clustername,
    }

    $galera_nodes = regsubst(
        pick(
            getvar("::percona_cluster_${clustername}"),
            $wsrep_node_address
        ),
        ',$',
        ''
    )

    $server_default_options = {
        'mysqld' => {
            'bind-address'                => $bind_address,
            'wsrep_node_address'          => $wsrep_node_address,
            'wsrep_cluster_address'       => "gcomm://${galera_nodes}",
            'wsrep_sst_auth'              => "sst:${sst_password}",
            'wsrep_cluster_name'          => $clustername,
            'wsrep_node_incoming_address' => $wsrep_node_address,
            'wsrep_sst_receive_address'   => $wsrep_node_address,
        },
    }

    $override_options = mysql_deepmerge(
        $default_options,
        $server_default_options,
        $mysql_options
    )

    class {'::mysql::server' :
        package_ensure          => installed,
        package_manage          => true,
        package_name            => $mysql_package,
        service_provider        => 'systemd',
        service_name            => 'mysql.service',
        service_manage          => $mysql_service_manage,
        service_enabled         => $mysql_service_enable,
        create_root_user        => true,
        create_root_my_cnf      => true,
        restart                 => false,
        remove_default_accounts => true,
        root_password           => $root_password,
        override_options        => $override_options,
    }

    file {'/etc/logrotate.d/percona-server':
        ensure => file,
        source => "puppet:///modules/percona/server/percona-server.logrotate.${::osfamily}",
    }

    if $::osfamily == 'Debian' {
        file {'/etc/mysql/debian.cnf' :
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0600',
            require => Class['::mysql::server'],
            content => template('percona/server/debian_cnf.erb'),
        }

        mysql_user { 'debian-sys-maint@localhost':
            ensure                   => 'present',
            max_connections_per_hour => '0',
            max_queries_per_hour     => '0',
            max_updates_per_hour     => '0',
            max_user_connections     => '0',
            password_hash            => mysql_password($debian_password),
            require                  => Class['::mysql::server'],
        }
    }

    mysql_user{ 'sst@localhost':
      ensure        => 'present',
      password_hash => mysql_password($sst_password),
      require       => Class['mysql::server'],
    }
    mysql_grant { 'sst@localhost/*.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['RELOAD', 'LOCK TABLES', 'REPLICATION CLIENT'],
        table      => '*.*',
        user       => 'sst@localhost',
        require    => Mysql_user['sst@localhost'],
    }

}
