name 'email'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '1.0.0'
description 'Installs and configures email server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

recipe 'email', 'Installs and configures email server'

depends 'postgresql', '~> 4.0.6'
depends 'database', '~> 5.1.2'
depends 'php', '~> 1.9.0'
depends 'ark', '~> 1.1.0'

depends 'latest-git', '~> 1.1.9'
depends 'modern_nginx', '~> 1.2.7'

supports 'ubuntu'
