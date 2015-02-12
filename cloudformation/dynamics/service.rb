SparkleFormation.dynamic(:service) do |_name, _config={}|

  parameters do
    set!("#{_name}_service_run_list".to_sym) do
      description 'Run list for service'
      type 'CommaDelimitedList'
    end
  end

  _srv = nil

  if(_config[:style].to_s == 'node')
    _srv = dynamic!(:node, "#{_name}_service".to_sym)
    if(_config[:inherit_security_group])
      dynamic!(
        :apply_security_group,
        _config[:inherit_security_group],
        :node_prefix => "#{_name}_service"
      )
    end
  else
    _srv = dynamic!(:auto_scaling_group, "#{_name}_service".to_sym)
    if(_config[:inherit_security_group])
      dynamic!(
        :apply_security_group,
        _config[:inherit_security_group],
        :asg_prefix => "#{_name}_service"
      )
    end
  end

  _srv

end
