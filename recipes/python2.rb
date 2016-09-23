apt_repository 'python2.7' do
  uri 'ppa:fkrull/deadsnakes-python2.7'
  distribution node['lsb']['codename']
end

python_runtime '2'

link '/usr/local/bin/python' do
  to '/usr/bin/python2.7'
end
