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
            $garbd_service = 'garb.service'
            $config_file = '/etc/my.cnf'
            $includedir = '/etc/my.cnf.d'
            $wsrep_provider = '/usr/lib64/libgalera_smm.so'
        }
        'Debian': {
            $garbd_package = 'percona-xtradb-cluster-garbd-3'
            $mysql_package = 'percona-xtradb-cluster-56'
            $garbd_fix_systemd = true
            $garbd_params_location = '/etc/default/garbd'
            $garbd_service = 'garbd.service'
            $config_file = '/etc/mysql/my.cnf'
            $includedir = '/etc/mysql/conf.d'
            $wsrep_provider = '/usr/lib/libgalera_smm.so'
        }
        default: {
            fail("${::osfamily} is not supported by ${::module_name}")
        }
    }
}
