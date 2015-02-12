SparkleFormation.dynamic(:node) do |_name, _config={}|

  parameters do

    registry!(:instance_parameters, _name, _config)

    set!("#{_name}_key_name".to_sym) do
      default 'demo-infra'
      description 'SSH key name'
      type 'String'
    end

  end

  dynamic!(:security_group, _name, :resource_name_suffix => :node_security_group) do
    properties do
      group_description "Instance security group (#{_name})"
      security_group_ingress array!(
        -> {
          ip_protocol 'tcp'
          from_port '22'
          to_port '22'
          cidr_ip '0.0.0.0/0'
        }
      )
    end
  end

  _node_instance = dynamic!(:ec2_instance, _name, :resource_name_suffix => :node) do
    properties do |_current_props|
      image_id map!(:platforms, 'AWS::Region', ref!("#{_name}_instance_image_type".to_sym))
      instance_type ref!("#{_name}_instance_size".to_sym)
      key_name ref!("#{_name}_key_name".to_sym)
      security_groups [attr!("#{_name}_security_group".to_sym, 'GroupId')]
      registry!(:node_user_data, _name, _config)
    end
    depends_on _config[:depends] if _config[:depends]
    registry!(:chef_metadata, _name, _config)
  end

  outputs do
    set!("#{_name}_instance_address") do
      description "Public IP address of #{_name} instance"
      value attr!("#{_name}_node".to_sym, 'PublicIp')
    end
  end

  # Returns the dynamic node instance for yield to block on insertion
  _node_instance

end

SparkleFormation.dynamic_info(:node).tap do |metadata|
  metadata[:parameters] = {
    :depends => {
      :type => 'Array',
      :description => 'Resources this instance depends on'
    }
  }
end
