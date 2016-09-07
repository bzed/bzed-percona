define percona::server::nodes::export(
    $clustername,
    $galera_wsrep_node_address = $name,
) {
    $target = "/etc/facter/facts.d/percona_cluster_${clustername}.txt"
    @@concat::fragment { $::fqdn:
        target  => $target,
        content => "${galera_wsrep_node_address},",
        order   => '10',
        tag     => 'bzed-percona_cluster',
    }
}

