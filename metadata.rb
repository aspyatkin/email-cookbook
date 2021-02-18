name 'email'
maintainer 'Alexander Pyatkin'
maintainer_email 'aspyatkin@gmail.com'
license 'MIT'
version '1.6.1'
description 'Installs and configures email server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

recipe 'email', 'Installs and configures email server'

depends 'postgresql', '~> 6.1.1'
depends 'database', '~> 6.1.1'
depends 'php', '~> 2.0.0'
depends 'ark', '~> 3.1'
depends 'composer', '~> 2.2.0'

depends 'nginx'
depends 'tls', '~> 4.1'
depends 'poise-python', '>= 1.6.0'

depends 'localdns', '~> 1.1.0'

supports 'ubuntu'

depends 'vlt', '~> 0.2'
