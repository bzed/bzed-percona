class percona::server::config {

    $buffersize = floor( $::memorysize_mb * 0.86 )
    $pool_instances = ceiling( $buffersize / 1024 )

    $mysql_options = {
        'mysqld'             => {
            # SAFETY
            'max-allowed-packet'              => '16M',
            'max-connect-errors'              => '1000000',
            ### sane modes, but disabled as too much stuff is not sane... :(
            ## 'sql-mode'                        => 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY',
            ## 'innodb-strict-mode'              => '1',
            'sysdate-is-now'                  => '1',
            'innodb'                          => 'FORCE',
            'explicit_defaults_for_timestamp' => '0',

            # BINARY LOGGING
            'log-bin'          => '/var/lib/mysql_binlog/binary_log',
            'expire-logs-days' => '10',

            # MyISAM - just in case....
            'key-buffer-size' => '32M',
            'myisam-recover'  => 'FORCE,BACKUP',

            # INNODB
            'innodb-flush-method'          => 'O_DIRECT',
            'innodb-log-files-in-group'    => '2',
            'innodb-log-file-size'         => '512M',
            'innodb-file-per-table'        => '1',
            'innodb-buffer-pool-size'      => "${buffersize}M",
            'innodb_buffer_pool_instances' => $pool_instances,
            'innodb_io_capacity'           => '2000',
            'innodb_read_io_threads'       => '16',
            'innodb_write_io_threads'      => '16',


            # CACHES AND LIMITS
            'tmp-table-size'         => '32M',
            'max-heap-table-size'    => '32M',
            'query_cache_size'       => '0',
            'query_cache_type'       => '0',
            'max-connections'        => '1600',
            'thread-cache-size'      => '3200',
            'open-files-limit'       => '65535',
            'table-definition-cache' => '4096',
            'table-open-cache'       => '8000',
            'join_buffer_size'       => '1048576',
            'sort_buffer_size'       => '1048576',

            # LOGGING
            'long_query_time'               => '0.75',
            'log_queries_not_using_indexes' => '0',
            'slow_query_log'                => '1',
            'slow_query_log_file'           => "/var/log/mysql/${::hostname}-slow.log",

        },
    }

    $percona_options = {
        'mysqld'                              => {
            'datadir'                         => '/var/lib/mysql/data',
            #'bind-address'                    => $::ipaddress_eth0,
            #'wsrep_node_address'              => $::ipaddress_eth0,
            'wsrep_provider'                  => '/usr/lib/libgalera_smm.so',
            #'wsrep_cluster_address'           => "gcomm://${gcom_addresses}",
            'wsrep_slave_threads'             => ($::processorcount * 2),
            'wsrep_sst_method'                => 'xtrabackup-v2',
            #'wsrep_sst_auth'                  => "sst:${sst_password}",
            #'wsrep_cluster_name'              => $clustername,
            'binlog_format'                   => 'ROW',
            'default_storage_engine'          => 'InnoDB',
            'innodb_locks_unsafe_for_binlog'  => '1',
            'innodb_autoinc_lock_mode'        => '2',
            'query_cache_size'                => '0',
            'query_cache_type'                => '0',
            #'wsrep_node_incoming_address'     => $::ipaddress_eth0,
            #'wsrep_sst_receive_address'       => $::ipaddress_eth0,
            'explicit_defaults_for_timestamp' => 'FALSE',
            'innodb-flush-log-at-trx-commit'  => '0',
            'sync-binlog'                     => '0',
        },
    }

    $default_options = mysql_deepmerge($mysql_options, $percona_options)
}
