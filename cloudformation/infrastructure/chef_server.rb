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
    infra_asset_set not!(equals!(ref!(:infra_asset), 'unset'))
  end

  dynamic!(:load_balancer, :chef_server)

  dynamic!(:asg, :chef_server,
    :run_list => [],
    :load_balancers => [ref!(:chef_server_load_balancer)]
  )

  dynamic!(:ec2_security_group_ingress, :chef_server) do
    properties do
      group_id attr!(:chef_server_security_group, 'GroupId')
      ip_protocol 'tcp'
      from_port ref!(:chef_server_instance_port)
      to_port ref!(:chef_server_instance_port)
      source_security_group_name attr!(:chef_server_load_balancer, 'SourceSecurityGroup.GroupName')
      source_security_group_owner_id attr!(:chef_server_load_balancer, 'SourceSecurityGroup.OwnerAlias')
    end
  end

  resources.chef_server_launch_configuration do
    metadata('AWS::CloudFormation::Init') do
      _camel_keys_set(:auto_disable)
      config.delete!(:commands)
      config do
        # NOTE: We never want the secret used by nodes available on
        #       the server itself
        files.delete!('/etc/chef/encrypted_data_bag_secret')
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
              if(ENV['CHEF_CLIENT_KEY'])
                set!(ENV.fetch('KNIFE_USER', ENV.fetch('USER', 'unknown')).dup, 'creator.pub')
              end
            end
          end
        end
        if(ENV['CHEF_CLIENT_KEY'])
          files('/tmp/srv-stp/creator.pub') do
            content system!("openssl rsa -in #{ENV['CHEF_CLIENT_KEY']} -pubout")
          end
        else
          sources.set!(
            '/tmp/stable', join!(
              'https://', ref!(:infrastructure_bucket), '.s3.amazonaws.com/', 'stable-infra.zip'
            )
          )
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
        commands('00_create_required_directories') do
          command [
            'mkdir -p /tmp/chef/cookbooks /etc/chef',
            '/var/log/chef /var/chef/cookbooks/chef-server',
            '/var/chef/cookbooks/chef-server-populator /tmp/srv-stp'
          ].join(' ')
        end
        commands('01_fetch_chef_server_cookbook') do
          command 'wget -O /tmp/cstg https://codeload.github.com/opscode-cookbooks/chef-server/tar.gz/v2.1.4'
        end
        commands('02_fetch_chef_server_populator_cookbook') do
          command 'wget -O /tmp/csptg https://codeload.github.com/hw-cookbooks/chef-server-populator/tar.gz/develop'
        end
        commands('03_install_chef_client') do
          command join!(
            'curl -L https://www.opscode.com/chef/install.sh | bash -s -- -v ',
            ref!(:chef_client_version)
          )
        end
        commands('04_unpack_chef_server_cookbook') do
          command 'tar xzf /tmp/cstg -C /var/chef/cookbooks/chef-server --strip-components=1'
        end
        commands('05_unpack_chef_server_populator_cookbook') do
          command 'tar xzf /tmp/csptg -C /var/chef/cookbooks/chef-server-populator --strip-components=1'
        end
        commands('06_generate_validator_public_key') do
          command 'openssl rsa -in /etc/chef/validator.pem -pubout -out /tmp/srv-stp/validator.pub'
        end
        commands('07_initial_chef_server_provision') do
          command 'HOME=/root chef-solo -j /etc/chef-server/first_run.json --force-logger -L /var/log/chef/srv.log'
        end
        commands('08_ensure_iptables_hole_punched') do
          command 'iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT'
          ignoreErrors true
        end
        commands('10_upload_cookbooks') do
          command 'knife cookbook upload --all -k /etc/chef-server/admin.pem -u admin'
          cwd '/tmp/stable'
          ignoreErrors true
        end
        commands('11_upload_environments') do
          command 'knife environment from file environments/* -k /etc/chef-server/admin.pem -u admin'
          cwd '/tmp/stable'
          ignoreErrors true
        end
        commands('12_upload_roles') do
          command 'knife role from file roles/* -k /etc/chef-server/admin.pem -u admin'
          cwd '/tmp/stable'
          ignoreErrors true
        end
        commands('13_upload_data_bags') do
          command 'knife upload data_bags -k /etc/chef-server/admin.pem -u admin'
          cwd '/tmp/stable'
          ignoreErrors true
        end
        commands('14_provision_inception') do
          command 'chef-client -j /etc/chef/first_run.json'
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

  parameters.delete!(:chef_server_url)

  outputs do
    chef_server_url do
      description 'Chef server endpoint URL'
      value join!('https://', attr!(:chef_server_load_balancer, 'DNSName'))
    end
  end

end
