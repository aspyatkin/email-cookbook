id = 'email'

%w(
  spamassassin
  spamc
  libnet-dns-perl
  libmail-spf-perl
  libmail-dkim-perl
  pyzor
  razor
).each do |package_name|
  package package_name do
    action :install
  end
end
