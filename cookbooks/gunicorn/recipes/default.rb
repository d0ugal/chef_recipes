execute "pip-install-gunicorn" do
    command "/home/#{node[:user_name]}/.virtualenvs/#{node[:project_name]}/bin/pip install gunicorn"
end
