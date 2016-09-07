class percona::garbd(
    $clustername,
) {

    class { '::percona::server::nodes' :
        clustername => $clustername
    }


    $galera_nodes = regsubst(
        pick(
            getvar("::percona_cluster_${clustername}"),
            ''
        ),
        ',$',
        ''
    )

    if ($galera_nodes and !empty($galera_nodes)) {
        ensure_packages('percona-xtradb-cluster-garbd-3')

        # work around having a buggy init script.
        # with some luck they'll ship a systemd service for jessie at some point
        service { 'garbd.service' :
            ensure     => running,
            provider   => systemd,
            hasrestart => true,
            status     => '/etc/init.d/garbd status',
            hasstatus  => false,
            start      => '/bin/systemctl restart garbd.service',
            require    => File['/var/lib/galera'],
        }

        file { '/etc/default/garbd' :
            ensure  => file,
            owner   => root,
            group   => root,
            mode    => '0644',
            content => template('percona/garbd/defaults.erb'),
            notify  => Service['garbd.service'],
        }

        file_line { 'fix-garbd-init-script' :
            path   => '/etc/init.d/garbd',
            line   => 'exit $?',
            match  => '^exit 0',
            notify => Exec['garbd-systemctl-daemon-reload'],
        }
        exec { 'garbd-systemctl-daemon-reload' :
            path        => $::path,
            refreshonly => true,
            command     => 'systemctl daemon-reload',
        }

        file { '/var/lib/galera' :
            ensure => directory,
            owner  => nobody,
            group  => root,
            mode   => '0750',
        }
    } else {
        notify { '$galera_nodes is empty - no idea where to connect to yet' : }
    }

}
