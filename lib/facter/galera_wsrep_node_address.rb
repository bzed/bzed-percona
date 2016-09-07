Facter.add("galera_wsrep_node_address") do
  setcode do
    wsrep_node_address = Facter::Util::Resolution.exec('mysql -ssrBe "show global variables like \'wsrep_node_address\'')
    if wsrep_node_address and wsrep_node_address =~ /^wsrep_node_address/
      wsrep_node_address.split('\t')[1]
    end
  end
end
