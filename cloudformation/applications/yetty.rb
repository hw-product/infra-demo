SparkleFormation.new("yetty").load(:base, :chef).overrides do

  # app server node
  dynamic!(:asg, 'yetty',
    :run_list => [
      'role[yetty]'
    ],
    :load_balancers => [
      ref!(:yetty_load_balancer)
    ]
  )

  [80, 443].each do |port|
    dynamic!(:ec2_security_group_ingress, "elb_#{port}") do
      properties do
        source_security_group_name attr!(:yetty_load_balancer, 'SourceSecurityGroup.GroupName')
        source_security_group_owner_id attr!(:yetty_load_balancer, 'SourceSecurityGroup.OwnerAlias')
        from_port port
        to_port port
        group_name ref!(:yetty_security_group)
        ip_protocol 'tcp'
      end
    end
  end

  dynamic!(:load_balancer, 'yetty')

  parameters do
    yetty_load_balancer_port.default '80'
    yetty_instance_port.default '80'
    yetty_load_balancer_protocol.default 'HTTP'
    yetty_instance_protocol.default 'HTTP'
    yetty_load_balancer_hc_check_path.default '/'
  end

end
