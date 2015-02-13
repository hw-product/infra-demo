SparkleFormation.new(:chef_server).load(:base, :chef).overrides do

  description 'Chef Server'

  parameters do

    chef_server_live do
      description 'Live chef server for environment'
      type 'String'
      allowed_values ['Yes', 'No']
      default 'No'
    end

    chef_server_version do
      type 'String'
      default '11.1.5-1'
    end

    chef_client_run_list do
      type 'String'
      description 'Run list for chef server after initial bootstrap'
      default 'recipe[chef-server-populator]'
    end

    infra_asset do
      type 'String'
      description 'Current infrastructure code bundle'
      default 'unset'
    end

  end

  mappings.chef_server_settings do
    yes do
      tag 'true'
      backup_bucket 'chef-server-backups'
    end
    no do
      tag 'false'
      backup_bucket 'chef-server-backups-devmodes'
    end
  end

  conditions do
    infra_asset_set not!(equals!(ref!(:infra_asset, 'unset')))
  end

  dynamic!(:load_balancer, :chef_server)

  dynamic!(:asg, :chef_server,
    :run_list => [],
    :load_balancers => [ref!(:chef_server_load_balancer)]
  )

  dynamic!(:ec2_security_group_ingress, :chef_server) do
    properties do
      group_id attr!(:chef_server_security_group, 'GroupId')
      ip_protocol ref!(:chef_server_load_balancer_protocol)
      from_port ref!(:chef_server_load_balancer_instance_port)
      to_port ref!(:chef_server_load_balancer_instance_port)
      source_security_group_name ref!(:chef_server_load_balancer_security_name)
      source_security_group_owner_id ref!(:chef_server_load_balancer_security_id)
    end
  end

  resources.chef_server_launch_configuration do
    metadata('AWS::CloudFormation::Init') do
      _camel_keys_set(:auto_disable)
      config.delete!(:commands)
      config do
        # files('/tmp/stable-infra.tgz') do
        #   source join!(
        #     'https://s3.amazonaws.com', ref!(:infrastructure_bucket), 'stable-infra.tgz',
        #     :options => {
        #       :delimiter => '/'
        #     }
        #   )
        #   mode '000400'
        #   owner 'root'
        #   group 'root'
        #   authentication 'InfrastructureBucketCredentials'
        # end
        files('/etc/chef-server/first_run.json') do
          content do
            run_list [
              'recipe[chef-server]',
              'recipe[chef-server-populator]'
            ]
            set!('chef-server') do
              version ref!(:chef_server_version)
            end
            chef_server_populator.server_url 'https://127.0.0.1'
            chef_server_populator.base_path '/tmp/srv-stp'
            chef_server_populator.clients do
              set!('chef-validator', 'validator.pub')
              set!(ENV.fetch('KNIFE_USER', ENV.fetch('USER', 'unknown')).dup, 'creator.pub')
            end
          end
        end
        files('/tmp/srv-stp/creator.pub') do
          content system!("openssl rsa -in #{ENV['CHEF_CLIENT_KEY']} -pubout")
        end
        files('/etc/chef/client.rb') do
          content "chef_server_url 'https://127.0.0.1'\n" <<
            "validation_key '/etc/chef/validator.pem'\n" <<
            "validation_client_name 'chef-validator'\n"
        end
        files('/etc/chef/first_run.json') do
          content do
            run_list [ref!(:chef_client_run_list)]
          end
        end
        commands('00_a') do
          command [
            'mkdir -p /tmp/chef/cookbooks /etc/chef',
            'wget -O /tmp/cstg http://bit.ly/Yf8tTb', # @note this is the chef server cookbook
            'wget -O /tmp/csptg http://bit.ly/Yf8ztU', # @note this is the chef server populator cookbook
            'curl -L https://www.opscode.com/chef/install.sh | bash -s -- -v 11.18.0',
            'mkdir -p /var/log/chef /var/chef/cookbooks/chef-server /var/chef/cookbooks/chef-server-populator /tmp/srv-stp',
            'tar xzf /tmp/cstg -C /var/chef/cookbooks/chef-server --strip-components=1',
            'tar xzf /tmp/csptg -C /var/chef/cookbooks/chef-server-populator --strip-components=1',
            'openssl rsa -in /etc/chef/validator.pem -pubout -out /tmp/srv-stp/validator.pub',
            'HOME=/root chef-solo -j /etc/chef-server/first_run.json --force-logger -L /var/log/chef/srv.log',
            'iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT',
            'tar xzf /tmp/stable-infra.tgz -C /tmp/stable --strip-components=1',
            'cd /tmp/stable',
            'knife cookbook upload --all -k /etc/chef-server/admin.pem -u admin',
            'knife role from file roles/* -k /etc/chef-server/admin.pem -u admin',
            'knife environment from file environments/* -k /etc/chef-server/admin.pem -u admin',
            'knife upload data_bags -k /etc/chef-server/admin.pem -u admin',
            'chef-client -j /etc/chef/first_run.json'
          ].join(';')
        end
      end
    end
  end

  parameters do
    chef_server_instance_image_type.default 'ubuntu1204'
    chef_server_instance_size.default 'm3.medium'
    chef_server_load_balancer_port.default '443'
    chef_server_instance_port.default '443'
    chef_server_load_balancer_protocol.default 'TCP'
    chef_server_instance_protocol.default 'TCP'
  end

end
