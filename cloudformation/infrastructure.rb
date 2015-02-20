SparkleFormation.new(:infrastructure) do
  nest!(:infrastructure__chef_server)
  nest!(:infrastructure__gemstore)
  nest!(:applications__wemux)
  nest!(:applications__yetty)
end
