# This class exists to avoid a dashboard jobs when job names are not sortered
# in the jenkins XML configuration
class jenkinsjobs::dashboard {
  package {
    'python-lxml':
      ensure => 'installed'
  }
  file {
    '/usr/local/bin/fix-dashboard-config.py':
      ensure => present,
      source => "puppet:///modules/${module_name}/fix-dashboard-config.py",
      mode   => '0755',
  }
  exec {
    'create-jenkins-config':
      path    => $::path,
      command => "java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://127.0.0.1:8080/ reload-configuration",
      creates => '/var/lib/jenkins/config.xml',
      require => Service['jenkins'],
  }
  exec {
    'fix-dashboard-config':
      command     => '/usr/local/bin/fix-dashboard-config.py /var/lib/jenkins/config.xml',
      refreshonly => true,
      require     => [
        File['/usr/local/bin/fix-dashboard-config.py'],
        Package['python-lxml'],
        Exec['create-jenkins-config'],
      ],
      notify  => Exec['reload-jenkins'],
  }
}
