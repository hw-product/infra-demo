SparkleFormation.new("yetty").load(:base, :chef).overrides do

  parameters do
    set!(:min_nodes) do
      type 'String'
      default '1'
    end
    set!(:max_nodes) do
      type 'String'
      default '1'
    end
  end

  # app server node
  dynamic!(:asg, 'yetty_app',
    :run_list => %w[
      recipe[yetty]
    ],
    :asg_min => ref!(:min_nodes),
    :asg_max => ref!(:max_nodes),
    :load_balancers => [ref!(:yetty_app_load_balancer)]
  )

  [80, 443].each do |port|
    dynamic!(:ec2_security_group_ingress, "elb_#{port}") do
      properties do
        source_security_group_name attr!(:yetty_app_load_balancer, 'SourceSecurityGroup.GroupName')
        source_security_group_owner_id attr!(:yetty_app_load_balancer, 'SourceSecurityGroup.OwnerAlias')
        from_port port
        to_port port
        group_name ref!(:yetty_app_security_group)
        ip_protocol 'tcp'
      end
    end
  end

  dynamic!(:load_balancer, 'yetty_app') do
    properties do
      listeners array!(
        -> {
          load_balancer_port 80
          instance_port 80
          protocol 'HTTP'
        }
      )

      health_check do
        target 'HTTP:80/'
        healthy_threshold '3'
        unhealthy_threshold '5'
        interval '30'
        timeout '5'
      end

      availability_zones azs!
    end
  end
end
