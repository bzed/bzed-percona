class percona::server(
    $clustername,
    $wsrep_node_address = $::ipaddress,
) {

    ::percona::server::nodes::export { $wsrep_node_address :
        clustername => $clustername
    }

    class { '::percona::server::nodes' :
        clustername => $clustername
    }


}
