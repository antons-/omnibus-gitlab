#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

gitlab_core_source_dir = "/opt/gitlab/embedded/service/gitlab-core"
gitlab_core_dir = node['gitlab']['gitlab-core']['dir']
gitlab_core_etc_dir = File.join(gitlab_core_dir, "etc")
gitlab_core_working_dir = File.join(gitlab_core_dir, "working")
gitlab_core_tmp_dir = File.join(gitlab_core_dir, "tmp")
gitlab_core_public_uploads_dir = node['gitlab']['gitlab-core']['uploads_directory']
gitlab_core_log_dir = node['gitlab']['gitlab-core']['log_directory']

[
  gitlab_core_dir,
  gitlab_core_etc_dir,
  gitlab_core_working_dir,
  gitlab_core_tmp_dir,
  gitlab_core_public_uploads_dir,
  gitlab_core_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['gitlab']['user']['username']
    mode '0700'
    recursive true
  end
end

should_notify_unicorn = OmnibusHelper.should_notify?("unicorn")

template_symlink File.join(gitlab_core_etc_dir, "secret") do
  link_from File.join(gitlab_core_source_dir, ".secret")
  source "secret_token.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[unicorn]' if should_notify_unicorn
end

template_symlink File.join(gitlab_core_etc_dir, "database.yml") do
  link_from File.join(gitlab_core_source_dir, "config/database.yml")
  source "database.yml.postgresql.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :restart, 'service[unicorn]' if should_notify_unicorn
end

template_symlink File.join(gitlab_core_etc_dir, "gitlab.yml") do
  link_from File.join(gitlab_core_source_dir, "config/gitlab.yml")
  source "gitlab.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-core'].to_hash)
  notifies :restart, 'service[unicorn]' if should_notify_unicorn
end

template_symlink File.join(gitlab_core_etc_dir, "rack_attack.rb") do
  link_from File.join(gitlab_core_source_dir, "config/initializers/rack_attack.rb")
  source "rack_attack.rb.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node['gitlab']['gitlab-core'].to_hash)
  notifies :restart, 'service[unicorn]' if should_notify_unicorn
end

directory node['gitlab']['gitlab-core']['satellites_path'] do
  owner node['gitlab']['user']['username']
  group node['gitlab']['user']['group']
  recursive true
end

# replace empty directories in the Git repo with symlinks to /var/opt/gitlab
{
  "/opt/gitlab/embedded/service/gitlab-core/tmp" => gitlab_core_tmp_dir,
  "/opt/gitlab/embedded/service/gitlab-core/public/uploads" => gitlab_core_public_uploads_dir,
  "/opt/gitlab/embedded/service/gitlab-core/log" => gitlab_core_log_dir
}.each do |link_dir, target_dir|
  link link_dir do
    to target_dir
  end
end

execute "chown -R #{node['gitlab']['user']['username']} /opt/gitlab/embedded/service/gitlab-core/public"
