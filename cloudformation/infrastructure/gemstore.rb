SparkleFormation.new(:gemstore).load(:base, :chef).overrides do

  description 'Custom Gem Store'

  dynamic!(:load_balancer, :gemstore)
  dynamic!(:asg, :gemstore,
    :run_list => ['role[gemstore]'],
    :load_balancers => [ref!(:gemstore_load_balancer)]
  )

  parameters do
    gemstore_instance_size.default 'm1.small'
    gemstore_load_balancer_port.default '443'
    gemstore_instance_port.default '443'
    gemstore_load_balancer_protocol.default 'TCP'
    gemstore_instance_protocol.default 'TCP'
    gemstore_load_balancer_hc_check_path.default '/'
  end

  outputs do
    gemstore_url do
      description 'URL for gemstore'
      value join!('https://', attr!(:gemstore_load_balancer, 'DNSName'))
    end
  end

end
