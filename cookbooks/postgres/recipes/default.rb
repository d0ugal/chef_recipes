# We give away straight off that while this is a postgres recipe, its a 
# postgres recipe for Python.
%w{postgresql python-psycopg2}.each do |pkg|
  package pkg do
    action :install
  end
end

# This is basically a big hack - I can't find a nice way to create a user and
# give them a password easily.
execute "create-user-#{node[:project_name]}" do
    command "sudo -u postgres psql -c \"CREATE ROLE #{node[:project_name]} NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN PASSWORD \'#{node[:project_name]}\';\""
end

# Create a database with the same name as the project and also with the owner
# set to the user we just created.
execute "create-db-#{node[:project_name]}" do
    command "sudo -u postgres createdb -O #{node[:project_name]} #{node[:project_name]}"
end
