# clustercheck.pp

class percona::server::clustercheck (
    $user,
    $password,
    $logfile = '/var/log/clustercheck.log',
    $mysqlconfig = '/etc/mysql/my.cnf',
) {
    $options = {
        'CS_USER'     => $user,
        'CS_PASSWORD' => $password,
        'LOGFILE'     => $logfile,
        'MYS_CONFIG'  => $mysqlconfig,
    }
    file{'/etc/systemd/system/clustercheck.socket':
        ensure  => file,
        source  => 'puppet:///modules/percona/server/clustercheck.socket',
        require => File['/etc/systemd/system/clustercheck@.service'],
        notify  => [Service['clustercheck.socket'], Exec['clusterchk-systemctl-daemon-reload']],
    }
    file{'/etc/systemd/system/clustercheck@.service':
        ensure  => file,
        source  => 'puppet:///modules/percona/server/clustercheck@.service',
        require => File['/etc/default/clustercheck'],
        notify  => [Service['clustercheck.socket'], Exec['clusterchk-systemctl-daemon-reload']],
    }
    file{'/etc/systemd/system/clustercheck.service':
        ensure => absent,
        force  => true,
        notify => Exec['clusterchk-systemctl-daemon-reload'],
    }
    file{'/etc/default/clustercheck':
        ensure  => file,
        content => join( sort(join_keys_to_values($options,'=')),"\n"),
    }
    service{'clustercheck.socket':
        ensure    => running,
        enable    => true,
        provider  => 'systemd',
        require   => File['/etc/systemd/system/clustercheck.socket'],
        subscribe => Exec['clusterchk-systemctl-daemon-reload'],
    }
    exec{'clusterchk-systemctl-daemon-reload':
        path        => $::path,
        refreshonly => true,
        command     => 'systemctl daemon-reload',
    }
    mysql_user{ "${user}@localhost" :
        ensure        => 'present',
        password_hash => mysql_password($password),
        require       => Class['mysql::server'],
    }
    mysql_grant { "${user}@localhost/*.*":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['PROCESS'],
        table      => '*.*',
        user       => "${user}@localhost",
        require    => Mysql_user['clusterchk@localhost'],
    }
}
