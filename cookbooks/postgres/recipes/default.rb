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

cookbook_file "/etc/postgresql/8.4/main/pg_hba.conf" do
    source "pg_hba.conf"
    mode 0600
    owner "postgres"
    group "postgres"
    action :create
end

# Hackin' it up.

service "postgresql" do
  service_name "postgresql-8.4"
  supports :restart => true, :status => true, :reload => true
  action :restart
end

execute "postgres-listen" do
    command "echo \"listen_addresses = '*'\" >> /etc/postgresql/8.4/main/postgresql.conf"
    notifies :restart, resources(:service => "postgresql")
end

execute "postgres-change-password" do
    command "sudo -u postgres psql -c \"ALTER ROLE postgres WITH PASSWORD 'postgres'\""
end

# This is basically a big hack - I can't find a nice way to create a user and
# give them a password easily.
execute "postgres-createuser" do
    command "sudo -u postgres psql -c \"CREATE ROLE #{node[:project_name]} NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD \'#{node[:project_name]}\';\""
    not_if "sudo -u postgres psql -c \"SELECT * FROM pg_user;\" | grep #{node['project_name']}"
end

if node[:gis]
  template_commands = [
    "createdb -E UTF8 template_postgis -T template0 -l en_US.utf8",
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

if node[:gis] 
  template = "template_postgis" 
else 
  template = "template0"
end
  

# Create a database with the same name as the project and also with the owner
# set to the user we just created.
execute "postgres-createdb" do
    command "sudo -u postgres  createdb -T #{template} -E UTF8  -l en_US.utf8 -O #{node[:project_name]} #{node[:project_name]}"
    not_if "sudo -u postgres psql -c \"SELECT * FROM pg_database;\" | grep #{node['project_name']}"
end