# We give away straight off that while this is a postgres recipe, its a
# postgres recipe for Python.
%w{postgresql python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end

if node[:gis]
    %w{postgresql-server-dev-8.4 postgresql-8.4-postgis}.each do |pkg|
      package pkg do
        action :install
      end
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

        if info.has_key?("gis") and info[:gis]
          template_commands = [
            "createdb -E UTF8 template_postgis -T template0",
            "createlang -d template_postgis plpgsql",
            "psql -d postgres -c \"UPDATE pg_database SET datistemplate='true' WHERE datname='template_postgis';\"",
            "psql -d template_postgis -f /usr/share/postgresql/8.4/contrib/postgis.sql",
            "psql -d template_postgis -f /usr/share/postgresql/8.4/contrib/spatial_ref_sys.sql",
            "psql -d template_postgis -c \"GRANT ALL ON geometry_columns TO PUBLIC;\"",
            "psql -d template_postgis -c \"GRANT ALL ON spatial_ref_sys TO PUBLIC;\""
          ]

          template_commands.each_with_index do |cmd, i|
            execute "postgis-template-create-step-#{i+1}" do
              command cmd
              user "postgres"
            end
          end

        end

        if info.has_key?("gis") and info[:gis]
          template = "template_postgis"
        else
          template = "template0"
        end

        execute "postgres-createdb-#{info[:name]}" do
            command "sudo -u postgres -- createdb -T #{template} -E UTF8 -O #{info[:username]} #{name}"
            not_if "sudo -u postgres -- psql -c \"SELECT * FROM pg_database;\" | grep -i #{name}"
        end

    end

end