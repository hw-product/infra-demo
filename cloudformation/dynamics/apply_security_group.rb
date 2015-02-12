SparkleFormation.dynamic(:apply_security_group) do |_name, _config={}|

  parameters do
    set!("#{_name}_security_group_id".to_sym) do
      type 'String'
      description 'Security group ID'
    end
  end

  if(_config[:asg_prefix])
    resources("#{_config[:asg_prefix]}_launch_configuration".to_sym) do
      properties do |current_properties|
        security_groups current_properties.security_groups.push(
          ref!("#{_name}_security_group_id".to_sym)
        )
      end
    end
  end

  if(_config[:node_prefix])
    resources("#{_config[:node_prefix]}_node".to_sym) do
      properties do |current_properties|
        security_groups current_properties.security_groups.push(
          ref!("#{_name}_security_group_id".to_sym)
        )
      end
    end
  end

end
