id = 'email'

%w(
  clamav-base
  libclamav6
  clamav-daemon
  clamav-freshclam
  arj
  bzip2
  file
  nomarch
  cpio
  lzop
  cabextract
  apt-listchanges
  p7zip
  rpm
  unrar-free
  libsnmp-perl
  gzip
  lhasa
  pax
  rar
  unrar
  unzip
  zip
  zoo
  tnef
  ripole
).each do |package_name|
  package package_name do
    action :install
  end
end

execute 'Update ClamAV virus signature databases' do
  command 'freshclam'
  user node[id]['clamav']['service']['user']
  group node[id]['clamav']['service']['group']
  action :run
end

service 'clamav-daemon' do
  action [:enable, :start]
end
