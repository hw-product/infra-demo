SparkleFormation.new(:infrastructure) do
  nest!(:infrastructure__gemstore)
  nest!(:applications__wemux)
  nest!(:applications__yetty)
end
