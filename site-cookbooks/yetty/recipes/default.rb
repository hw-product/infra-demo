#
# Author:: Heavy Water Operations LLC <support@hw-ops.com>
#
# Copyright 2014, Heavy Water Operations LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'build-essential'

chef_gem 'yetty'

include_recipe 'runit'
include_recipe 'nginx'
include_recipe 'unicorn'

deploy_dir = node[:yetty][:deploy_directory]

directory deploy_dir do
  action :create
  recursive true
  mode 0755
end


file ::File.join(deploy_dir, 'config.json') do
  content Chef::JSONCompat.to_json_pretty(node[:yetty][:config])
  mode 0640
  group node[:nginx][:user]
end


file ::File.join(deploy_dir, 'config.ru') do
  content "require 'yetty'\nrun Yetty::Site::App"
  mode 0644
end

node.default[:unicorn][:worker_timeout] = 60
node.default[:unicorn][:preload_app] = false
node.default[:unicorn][:worker_processes] = 1
node.default[:unicorn][:preload_app] = false
node.default[:unicorn][:before_fork] = 'sleep 1'
node.default[:unicorn][:port] = '8888'
node.set[:unicorn][:options] = { :tcp_nodelay => true, :backlog => 100}

unicorn_config "/etc/unicorn/yetty.rb" do
  listen({ node[:unicorn][:port] => node[:unicorn][:options] })
  working_directory deploy_dir
  worker_timeout node[:unicorn][:worker_timeout]
  preload_app node[:unicorn][:preload_app]
  worker_processes node[:unicorn][:worker_processes]
  before_fork node[:unicorn][:before_fork]
end

runit_service 'unicorn' do
  default_logger true
end

template '/etc/nginx/sites-available/unicorn' do
  source 'unicorn-nginx.erb'
end

nginx_site 'default' do
  enable false
end

nginx_site 'unicorn' do
  enable true
end
