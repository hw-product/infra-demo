SparkleFormation.new('wemux').load(:base, :chef).overrides do

  description 'Demo pairing stack'

  dynamic!(:node, :wemux, :run_list => ['role[wemux]'])

  parameters do
    wemux_instance_size.default 'm1.small'
  end

end
