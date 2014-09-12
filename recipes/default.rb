#
# Cookbook Name:: elk
# Recipe:: default
#
# Copyright (C) 2014 Precision Development
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apt"

apt_package "openjdk-7-jre" do
	action :install
end

node.set['rabbitmq']['default_user'] = "logstash"
node.set['rabbitmq']['default_pass'] = "loggin"

include_recipe "rabbitmq::default"
include_recipe "rabbitmq::mgmt_console"

rabbitmq_user "logstash" do
	password "loggin"
	action :add
end

rabbitmq_user "logstash" do
	tag "administrator"
	action :set_tags
end

rabbitmq_vhost "/" do
	action :add
end

rabbitmq_user "logstash" do
	vhost "/"
	permissions ".* .* .*"
	action :set_permissions
end

remote_file "/tmp/elasticsearch-1.3.2.deb" do
	source "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.deb"
	mode 0644
	checksum "156a38c5a829e5002ae8147c6cac20effe6cd065"
end

dpkg_package "elasticsearch" do
	source "/tmp/elasticsearch-1.3.2.deb"
	action :install
end

service "elasticsearch" do
	action :start
end

remote_file "/tmp/logstash_1.4.2-1-2c0f5a1_all.deb" do
	source "https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash_1.4.2-1-2c0f5a1_all.deb"
	mode 0644
	checksum "fb2c384f61b6834094b31a34d75b58d00c71d81a"
end

dpkg_package "logstash" do
	source "/tmp/logstash_1.4.2-1-2c0f5a1_all.deb"
	action :install
end

template "/etc/logstash/conf.d/rabbitmq.conf" do
	source "rabbitmq_logstash.conf.erb"
end

service "logstash" do
	action :start
end

remote_file "/tmp/kibana-3.1.0.tar.gz" do
	source "https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz"
	mode 0644
	notifies :run, "bash[extract kibana]"
end

directory "/opt/www/kibana" do
	action :create
	recursive true
end

bash "extract kibana" do
	code <<-EOH
	tar -zxvf /tmp/kibana-3.1.0.tar.gz
	rm -p /opt/www/kibana
	mv kibana-3.1.0/* /opt/www/kibana
	EOH
	action :nothing
	supports :run => true
end

apt_package "nginx" do
	action :install
end

template "/etc/nginx/sites-enabled/default" do
	source "default.erb"
	notifies :restart, "service[nginx]"
end

template "/opt/www/kibana/config.js" do
	source "config.js.erb"
end

service "nginx" do
	action :start
	supports :restart => true
end