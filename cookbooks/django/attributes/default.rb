%w{ack python-setuptools python-dev vim}.each do |pkg|
  package pkg do
    action :install
  end
end
