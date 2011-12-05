# We give away straight off that while this is a postgres recipe, its a
# postgres recipe for Python.
%w{libpq-dev postgresql python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end


pg_hba_dev = node['development_environment']

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

if node['development_environment'] and node.has_key?("postgres_password")
    execute "postgres-change-password" do
        command "sudo -u postgres psql -c \"ALTER ROLE postgres WITH PASSWORD '#{node[:postgres_password]}'\""
    end
end


if node.has_key?("databases")

    node.databases.each do |name, info|

      # We are looking for databases with gis enabled. If its not, 'continue'
      if not info.has_key?("gis") or not info[:gis]
        next
      end

      execute "post-gis" do
          command 'echo "
      deb http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu lucid main
      deb-src http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu lucid main" >> /etc/apt/sources.list
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160
      sudo apt-get update'
          not_if "sudo cat /etc/apt/sources.list | grep -i ubuntugis-unstable"
      end

      %w{python-psycopg2 postgresql binutils proj gdal-bin postgresql-8.4-postgis
          postgresql-server-dev-8.4}.each do |pkg|
        package pkg do
          action :install
        end
      end

      # It seems Chef's package installer doesn't support virtual packages.
      execute "gdal-contrib" do
          command "sudo apt-get install -y gdal-contrib"
      end

      script "postgres-postgis-template" do
        interpreter "bash"
        user "postgres"
        cwd "/tmp"
        code "
        wget http://docs.djangoproject.com/en/1.3/_downloads/create_template_postgis-1.5.sh -O /tmp/create_template_postgis-1.5.sh
        bash /tmp/create_template_postgis-1.5.sh
        "
        not_if "sudo -u postgres -- psql -c \"SELECT datname FROM pg_database where datistemplate=true;\" | grep -i template_postgis"
      end

      # We only want to do this for the first database with gis enabled.
      break

    end

    node.databases.each do |name, info|

      execute "postgres-createuser-#{info[:username]}" do
          command "sudo -u postgres -- psql -c \"CREATE ROLE #{info[:username]} NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD \'#{info[:password]}\';\""
          not_if "sudo -u postgres -- psql -c \"SELECT usename FROM pg_user;\" | grep -i #{info[:username]}"
      end

      if info.has_key?("gis") and info[:gis]
        template = "template_postgis"
      else
        template = "template0"
      end

      execute "postgres-createdb-#{info[:name]}" do
          command "sudo -u postgres -- createdb -T #{template} -E UTF8 -O #{info[:username]} #{name}"
          not_if "sudo -u postgres -- psql -c \"SELECT datname FROM pg_database;\" | grep -i #{name}"
      end

    end

end
