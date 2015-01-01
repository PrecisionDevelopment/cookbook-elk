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

remote_file "/usr/local/bin/rabbitmqadmin" do
	source "http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v3_3_5/bin/rabbitmqadmin"
	mode 755
	notifies :restart, "service[rabbitmq-server]", :immediately
end

bash "create exchange" do
	code "rabbitmqadmin --username=logstash --password=loggin declare exchange name=logstash type=topic durable=true"
end

bash "create queue" do
	code "rabbitmqadmin --username=logstash --password=loggin declare queue name=logstash durable=true"
end

bash "bind queue to exchange" do
	code "rabbitmqadmin declare binding source=logstash destination_type=queue destination=logstash routing_key=\"log4net.gelf.appender\""
end

remote_file "/tmp/elasticsearch-1.3.2.deb" do
	source "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.deb"
	mode 0644
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

directory "/opt/www/kibana" do
	action :create
	recursive true
end

remote_file "/tmp/kibana-3.1.0.tar.gz" do
	source "https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz"
	mode 0644
	notifies :run, "bash[extract kibana]", :immediately
end

bash "extract kibana" do
	code <<-EOH
	tar -zxvf /tmp/kibana-3.1.0.tar.gz
	rm -rf /opt/www/kibana/*
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
	notifies :restart, "service[nginx]", :immediately
end

template "/opt/www/kibana/config.js" do
	source "config.js.erb"
end

service "nginx" do
	action :start
	supports :restart => true
end
