#Install Apache2
apache_packages = ['apache2',
                   'libapache2-mod-php5'] 
apache_packages.each do |apache|
  apt_package apache do
    action :install
  end
end

bash "Create a symbolic link " do
  user "root"
  code <<-EOH
    if [ ! -L /var/www ]; then
      sudo rm -rf /var/www
      sudo ln -s /vagrant /var/www
    fi
  EOH
end

bash "Config ServerName" do
  user "root"
  code <<-EOH
    echo ServerName 127.0.0.1 >> /etc/apache2/apache2.conf
  EOH
end

service "apache2" do
  stop_command "sudo service apache2 stop"
  start_command "sudo service apache2 start"
  status_command "sudo service apache2 status"
  restart_command "sudo service apache2 restart"
  action :start
end

# Activate the SSL Module
# @see https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-apache-for-ubuntu-12-04
execute "sudo mkdir /etc/apache2/ssl"
execute "Activate the SSL Module" do
  command "sudo a2enmod ssl"
  notifies :restart, resources(:service => "apache2")
  command 'sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt -subj "/C=BR/ST=Sao Paulo/L=Sao Paulo/O=Global Security/OU=IT Department/CN=127.0.1.1"'
end

template "default-ssl" do
  path "/etc/apache2/sites-available/default-ssl"
  source "default-ssl.erb"
  owner "root"
  group "root"
  mode 0644
end

template "ports.conf" do
  path "/etc/apache2/ports.conf"
  source "ports.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

execute "Activate the New Virtual Host" do
  command "sudo a2ensite default-ssl"
  notifies :restart, resources(:service => "apache2")
end

# Enable mod_rewrite of Apache2
# @see http://jaydson.org/habilitar-mod_rewrite-no-apache/
execute "Enable mod_rewrite of Apache2" do
  command "sudo a2enmod rewrite"
  notifies :restart, resources(:service => "apache2")
end

template "default" do
  path "/etc/apache2/sites-available/default"
  source "default.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "apache2")
end