# Setup garbd

class percona::garbd(
    $clustername,
    $garbd_package,
) {

    class { '::percona::server::nodes' :
        clustername => $clustername,
    }
    require ::percona::params


    $galera_nodes = regsubst(
        pick_default(
            getvar("::percona_cluster_${clustername}"),
            ''
        ),
        ',$',
        ''
    )
    $package = pick($garbd_package, $::percona::garbd_package, 'percona-xtradb-cluster-garbd-56')

    if ($galera_nodes and !empty($galera_nodes)) {
        ensure_packages($package)

        if $::percona::params::garbd_fix_systemd == true {
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
        }
        else {
            service{ 'garbd.service' :
                ensure   => running,
                enable   => true,
                provider => systemd,
                require  => File['/var/lib/galera'],
            }
        }

        file { $::percona::params::garbd_params_location :
            ensure  => file,
            owner   => root,
            group   => root,
            mode    => '0644',
            content => template('percona/garbd/defaults.erb'),
            notify  => Service['garbd.service'],
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
