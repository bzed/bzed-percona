# The good, old params.pp pattern :)

class percona::params {
    $bind_address = $::ipaddress
    $wsrep_node_address = $::ipaddress
    $buffersize = floor( $::memorysize_mb * 0.8 )
    $pool_instances = ceiling( $buffersize / 1024 )

    case $::osfamily {
        'RedHat': {
            $garbd_package = 'Percona-XtraDB-Cluster-garbd-3'
            $mysql_package = 'Percona-XtraDB-Cluster-56'
            $garbd_fix_systemd = false
            $garbd_params_location = '/etc/sysconfig/garb'
        }
        'Debian': {
            $garbd_package = 'percona-xtradb-cluster-garbd-3'
            $mysql_package = 'percona-xtradb-cluster-56'
            $garbd_fix_systemd = true
            $garbd_params_location = '/etc/default/garbd'
        }
        default: {
            fail("${::osfamily} is not supported by ${::module_name}")
        }
    }
}
