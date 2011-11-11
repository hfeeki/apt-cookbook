action :add do
  if Chef::Util.wan_up? && !::File.exists?("/etc/apt/sources.list.d/#{new_resource.repo_name}-source.list")
    Chef::Log.info "Adding #{new_resource.repo_name} repository to /etc/apt/sources.list.d/#{new_resource.repo_name}-source.list"
    # add key
    if new_resource.key && new_resource.keyserver
      execute "install-key #{new_resource.key}" do
        command "apt-key adv --keyserver #{new_resource.keyserver} --recv #{new_resource.key}"
      end
    elsif new_resource.key
      execute "install-key #{new_resource.key}" do
        command %{
          tmp_key=$(mktemp /tmp/key.XXXXX)
          curl #{new_resource.key} -o $tmp_key
          apt-key add $tmp_key
          rm $tmp_key
        }
      end
    end
    # build our listing
    repository = "deb"
    repository = "deb-src" if new_resource.deb_src
    repository = "# Created by the Chef apt_repository LWRP\n" + repository
    repository += " #{new_resource.uri}"
    repository += " #{new_resource.distribution}"
    new_resource.components.each {|component| repository += " #{component}"}
    # write out the file, replace it if it already exists
    file "/etc/apt/sources.list.d/#{new_resource.repo_name}-source.list" do
      owner "root"
      group "root"
      mode 0644
      content repository + "\n"
      action :create
    end
    e = execute "update package index" do
      command "apt-get update"
      action :run
    end
    e.run_action(:run)
    new_resource.updated_by_last_action(true)
  end
end

action :remove do
  if ::File.exists?("/etc/apt/sources.list.d/#{new_resource.repo_name}-source.list")
    Chef::Log.info "Removing #{new_resource.repo_name} repository from /etc/apt/sources.list.d/"
    file "/etc/apt/sources.list.d/#{new_resource.repo_name}-source.list" do
      action :delete
    end
    new_resource.updated_by_last_action(true)
  end
end
