name 'base'

run_list(
  'recipe[apt]',
  'recipe[chef-client::cron]',
  'recipe[chef-client::config]',
  'recipe[users::sysadmins]',
  'recipe[sudo]'
)

default_attributes(
  :chef_client => {
    :log_dir => '/var/log/chef',
    :log_file => 'client.log',
    :config => {
      :verify_api_cert => false
    },
    :cron => {
      :hour => '*',
      :minute => '*/30'
    }
  }
)

override_attributes(
  :authorization => {
    :sudo => {
      :include_sudoers_d => true,
      :passwordless => true
    }
  }
)
