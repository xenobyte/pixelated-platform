# configure and install the pixelated dispatcher
class pixelated::dispatcher{
  include ::pixelated::apt
  include ::pixelated::check_mk

  package{ ['python-tornado','pixelated-dispatcher','linux-image-amd64']:
    ensure => installed,
  }
  
  exec{'set_fingerprint_for_proxy':
    command => '/bin/echo "PIXELATED_MANAGER_FINGERPRINT=$(openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -noout -fingerprint -sha1 | cut -d'=' -f 2)" >> /etc/default/pixelated-dispatcher-proxy',
    refreshonly => true,
    subscribe   => Package['pixelated-dispatcher'],
  }
  exec{'set_fingerprint_for_manager':
    command => '/bin/echo "PIXELATED_PROVIDER_FINGERPRINT=$(openssl x509 -in /etc/x509/certs/leap_commercial.crt -noout -fingerprint -sha1 | cut -d'=' -f 2)" >> /etc/default/pixelated-dispatcher-manager',
    refreshonly => true,
    subscribe   => Package['pixelated-dispatcher'],
  }

  # Allow traffic from outside to dispatcher
  file { '/etc/shorewall/macro.pixelated_dispatcher':
    content => 'PARAM   -       -       tcp    8080',
    notify  => Service['shorewall'],
    require => Package['shorewall']
  }
  shorewall::rule {
      'net2fw-pixelated-dispatcher':
        source      => 'net',
        destination => '$FW',
        action      => 'pixelated_dispatcher(ACCEPT)',
        order       => 200;
  }
  # allow docker traffic
  shorewall::zone {'dkr': type => 'ipv4'; }
  shorewall::interface { 'docker0':
    zone      => 'dkr',
    options   => 'tcpflags,blacklist,nosmurfs';
  }
  shorewall::policy {
    'dkr-to-all':
      sourcezone      => 'dkr',
      destinationzone => 'all',
      policy          => 'ACCEPT',
      order           => 200;
  }
  shorewall::rule {
      'dkr2fw-https':
        source      => 'dkr',
        destination => '$FW',
        action      => 'HTTPS(ACCEPT)',
        order       => 201;
  }
  shorewall::rule {
      'dkr2fw-leap-api':
        source      => 'dkr',
        destination => '$FW',
        action      => 'leap_webapp_api(ACCEPT)',
        order       => 202;
  }
  shorewall::rule {
      'dkr2fw-leap-mx':
        source      => 'dkr',
        destination => '$FW',
        action      => 'leap_mx(ACCEPT)',
        order       => 203;
  }
}

