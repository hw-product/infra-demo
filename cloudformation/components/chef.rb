SparkleFormation.build do

  parameters do

    environment do
      description 'Chef environment'
      default '_default'
      allowed_values [ENV.fetch('KNIFE_USER', ENV.fetch('USER', 'unknown')), '_default', 'development', 'production']
      type 'String'
      disable_apply true
    end

    chef_server_url do
      description 'URL for the chef server'
      default ENV.fetch('KNIFE_CHEF_SERVER_URL', 'http://localhost')
      type 'String'
      disable_apply true
    end

    chef_client_version do
      description 'Chef client version'
      default '11.16.2'
      type 'String'
      disable_apply true
    end

  end

end
