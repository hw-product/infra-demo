current_dir = File.expand_path(File.dirname(__FILE__))
root_dir = File.dirname(current_dir)

log_level :info
log_location STDOUT

validation_client_name 'fission-validator'
validation_key ENV['KNIFE_VALIDATION_KEY']
chef_server_url ENV['KNIFE_CHEF_SERVER_URL']
cache_type 'BasicFile'
cache_options(:path => File.join(current_dir, '.checksums'))

chef_repo_path root_dir

if(ENV['DISABLE_LIBRARIAN'] == 'true')
  cookbook_path File.join(root_dir, 'vendor/cookbooks')
else
  require 'librarian/chef/integration/knife'
  cookbook_path Librarian::Chef.install_path
end

node_name ENV['KNIFE_USER'] || ENV['OPSCODE_USER'] || ENV['USER']
client_key ENV['KNIFE_CLIENT_KEY'] || ENV['OPSCODE_KEY'] || "~/.chef/#{ENV['USER']}.pem"

# Encrypted data bag items
knife[:secret_file] = ENV['SECRET_FILE']

# AWS credentials
knife[:aws_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
knife[:aws_secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']
knife[:region] = ENV['AWS_REGION']

# Rackspace credentials
knife[:rackspace_username] = ENV['RACKSPACE_USERNAME']
knife[:rackspace_api_key] = ENV['RACKSPACE_API_KEY']
knife[:rackspace_region] = ENV['RACSKPACE_REGION']

# Static EC2 config
knife[:aws_ssh_key_id] = 'fission-infra'
knife[:image] = 'ami-6aad335a'
knife[:flavor] = 'm1.small'
knife[:distro] = 'chef-full'

# Cloudformation configuration
knife[:cloudformation][:processing] = true
knife[:cloudformation][:options][:disable_rollback] = true
knife[:cloudformation][:options][:notification_topics] = ['arn:aws:sns:us-west-2:921689585014:fission_infra']
knife[:cloudformation][:ssh_attempt_users] = ['ubuntu']
knife[:cloudformation][:identity_file] = ENV['DEFAULT_SSH_IDENTITY_FILE']
knife[:cloudformation][:ignore_parameters] = ['Environment', 'Creator']
knife[:cloudformation][:nesting_bucket] = 'fission-cfn'

case ENV['PROVIDER'].to_s.downcase
when 'rackspace'
  knife[:cloudformation][:credentials] = Mash.new(
    :rackspace_username => knife[:rackspace_username],
    :rackspace_api_key => knife[:rackspace_api_key],
    :rackspace_region => knife[:rackspace_region]
  )
when 'openstack'
  knife[:cloudformation][:credentials] = Mash.new(
    :provider => :open_stack,
    :open_stack_username => ENV['OPENSTACK_USERNAME'],
    :open_stack_password => ENV['OPENSTACK_PASSWORD'],
    :open_stack_tenant_name => ENV['OPENSTACK_TENANT_NAME'],
    :open_stack_identity_url => ENV['OPENSTACK_IDENTITY_URL']
  )
else
  knife[:cloudformation][:options][:capabilities] = ['CAPABILITY_IAM']
  knife[:cloudformation][:credentials] = Mash.new(
    :aws_access_key_id => knife[:aws_access_key_id],
    :aws_secret_access_key => knife[:aws_secret_access_key],
    :aws_region => knife[:region],
    :aws_bucket_region => knife[:region]
  )
end

knife[:cloudformation][:ssh_attempt_users] = ['ubuntu']

if(ENV['CLOUDFORMATION_IDENTITY_FILE'])
  knife[:cloudformation][:identity_file] = ENV['CLOUDFORMATION_IDENTITY_FILE']
end
