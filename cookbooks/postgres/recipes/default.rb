# We give away straight off that while this is a postgres recipe, its a
# postgres recipe for Python.
%w{postgresql python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end

pg_hba_dev = node.has_key?("dev_env") and node.dev_env


if pg_hba_dev
    pg_hba_conf = "/etc/postgresql/8.4/main/pg_hba_dev.conf"
    pg_hba_conf_source = "pg_hba_dev.conf"
else
    pg_hba_conf = "/etc/postgresql/8.4/main/pg_hba.conf"
    pg_hba_conf_source = "pg_hba.conf"
end

cookbook_file pg_hba_conf do
    source pg_hba_conf_source
    mode 0600
    owner "postgres"
    group "postgres"
    action :create
end

service "postgresql" do
  service_name "postgresql-8.4"
  supports :restart => true, :status => true, :reload => true
  action :restart
end

if pg_hba_dev
    execute "postgres-listen" do
        command "echo \"listen_addresses = 'localhost'\" >> /etc/postgresql/8.4/main/postgresql.conf"
        notifies :restart, resources(:service => "postgresql")
    end
end

if node.has_key?("postgres_password")
    execute "postgres-change-password" do
        command "sudo -u postgres psql -c \"ALTER ROLE postgres WITH PASSWORD '#{node[:postgres_password]}'\""
    end
end


if node.has_key?("databases")

    node.databases.each do |name, info|

        execute "postgres-createuser-#{info[:username]}" do
            command "sudo -u postgres -- psql -c \"CREATE ROLE #{info[:username]} NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD \'#{info[:password]}\';\""
            not_if "sudo -u postgres -- psql -c \"SELECT * FROM pg_user;\" | grep -i #{node['project_db_user']}"
        end

        template = "template0"

        execute "postgres-createdb-#{info[:name]}" do
            command "sudo -u postgres -- createdb -T #{template} -E UTF8 -O #{info[:username]} #{name}"
            not_if "sudo -u postgres -- psql -c \"SELECT * FROM pg_database;\" | grep -i #{name}"
        end

    end

end
