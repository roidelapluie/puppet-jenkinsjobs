# = Class: jenkinsjobs
#
# Description of jenkinsjobs
#
# == Parameters:
#
# $param::   Description of parameter
#
# == Actions:
#
# == Requires:
#
# == Sample Usage:
#
class jenkinsjobs (
  $augeas_prefix_dashboard = $jenkinsjobs::params::augeas_prefix_dashboard,
  $augeas_element_portlet = $jenkinsjobs::params::augeas_element_portlet,
  $username = undef,
  $password = undef,
) inherits jenkinsjobs::params {
  ## Copy paste snippets:
  # template("${module_name}/template.erb")
  # source => "puppet:///modules/${module_name}/file"
  include jenkinsjobs::dashboard

  if ($password) {
    exec {
      'reload-jenkins':
        path        => $::path,
        command     => "java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://127.0.0.1:8080/ reload-configuration --username \"${username}\" --password \"${password}\"",
        refreshonly => true,
        require     => Service['jenkins'],
    }
  } else {
    exec {
      'reload-jenkins':
        path        => $::path,
        command     => 'java -jar /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar -s http://127.0.0.1:8080/ reload-configuration',
        refreshonly => true,
        require     => Service['jenkins'],
    }
  }
}

