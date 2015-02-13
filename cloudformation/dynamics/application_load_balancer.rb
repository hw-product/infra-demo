SparkleFormation.dynamic(:application_load_balancer) do |_name, _config={}|

  parameters do
    set!("#{_name}_load_balancer_port".to_sym) do
      type 'Number'
      default 80
    end
    set!("#{_name}_instance_port".to_sym) do
      type 'Number'
      default 80
    end
    set!("#{_name}_instance_protocol".to_sym) do
      type 'String'
      default 'HTTP'
    end
    set!("#{_name}_load_balancer_protocol".to_sym) do
      type 'String'
      default 'HTTP'
    end
    set!("#{_name}_load_balancer_hc_threshold".to_sym) do
      type 'String'
      default '2'
    end
    set!("#{_name}_load_balancer_hc_interval".to_sym) do
      type 'String'
      default '30'
    end
    set!("#{_name}_load_balancer_hc_check_path".to_sym) do
      type 'String'
      default '/'
    end
    set!("#{_name}_load_balancer_hc_timeout".to_sym) do
      type 'String'
      default '2'
    end
    set!("#{_name}_load_balancer_hc_unhealthy_threshold".to_sym) do
      type 'String'
      default '2'
    end
  end

  _lb_resource = dynamic!(:load_balancer, _name) do
    properties do
      availability_zones.set!('Fn::GetAZs', '')
      listeners array!(
        ->{
          protocol ref!("#{_name}_load_balancer_protocol".to_sym)
          load_balancer_port ref!("#{_name}_load_balancer_port".to_sym)
          instance_port ref!("#{_name}_instance_port".to_sym)
          instance_protocol ref!("#{_name}_instance_protocol".to_sym)
        }
      )
      health_check do
        healthy_threshold ref!("#{_name}_load_balancer_hc_threshold".to_sym)
        interval ref!("#{_name}_load_balancer_hc_interval".to_sym)
        target join!(
          ref!("#{_name}_instance_protocol".to_sym),
          ':',
          ref!("#{_name}_instance_port".to_sym)
        #  ref!("#{_name}_load_balancer_hc_check_path".to_sym)
        )
        timeout ref!("#{_name}_load_balancer_hc_timeout".to_sym)
        unhealthy_threshold ref!("#{_name}_load_balancer_hc_unhealthy_threshold".to_sym)
      end
    end
  end

  outputs do
    set!("#{_name}_load_balancer_id".to_sym) do
      value ref!("#{_name}_load_balancer".to_sym)
      description 'Internal ID of load balancer'
    end
    set!("#{_name}_load_balancer_port".to_sym) do
      value ref!("#{_name}_load_balancer_port".to_sym)
      description 'Load balancer port'
    end
    set!("#{_name}_load_balancer_instance_port".to_sym) do
      value ref!("#{_name}_instance_port".to_sym)
      description 'Instance port'
    end
    set!("#{_name}_load_balancer_security_name".to_sym) do
      value attr!("#{_name}_load_balancer".to_sym, 'SourceSecurityGroup.GroupName')
      description 'Security group source name of load balancer'
    end
    set!("#{_name}_load_balancer_security_id".to_sym) do
      value attr!("#{_name}_load_balancer".to_sym, 'SourceSecurityGroup.OwnerAlias')
      description 'Security group source ID of load balancer'
    end
    set!("#{_name}_load_balancer_public_ip".to_sym) do
      value attr!("#{_name}_load_balancer".to_sym, 'DNSName')
      description 'Public IPv4 address of load balancer'
    end
  end

  # ensure we return resource for direct overrides
  _lb_resource
end

SparkleFormation.dynamic_info(:application_load_balancer).tap do |metadata|
  metadata[:parameters] = {
  }
end
