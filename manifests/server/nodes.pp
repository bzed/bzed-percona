class percona::server::nodes(
    $clustername,
) {
    $target = "/etc/facter/facts.d/percona_cluster_${clustername}.txt"
    concat { $target:
        ensure => present,
    }
    concat::fragment { "percona_cluster_${clustername}_header":
        target  => $target,
        content => "percona_cluster_${clustername}=",
        order   => '01'
    }

    Concat::Fragment<<| target == $target and tag == 'bzed-percona_cluster' |>>
}
