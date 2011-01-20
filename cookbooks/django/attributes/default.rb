%w{zsh wget curl lynx git-core ack vim}.each do |pkg|
  package pkg do
    action :install
  end
end
