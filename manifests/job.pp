define jenkinsjobs::job(
  $git_repository,
  $customer_name,
  $job_template,
  $job_type,
  $job_name          = $title,
  $targets           = undef,
  $ensure            = 'present',
  $start_pipeline    = false,
  $assigned_node     = undef,
  $next_job          = undef,
  $previous_job      = undef,
  $dashboard_view    = undef,
  $promotions        = undef,
  $package_name      = undef,
  $vhost_docroot     = undef,
  $custom_modules    = undef,
  $qa_url            = undef,
  $qa_db             = undef,
  $qa_password       = undef,
){

  if ($ensure == 'absent'){
    $directory_ensure = 'directory'
    $directory_force  = false
    $file_ensure      = 'absent'
    $job_ensure       = 'disabled'
  }
  elsif ($ensure == 'purged') {
    $directory_ensure = 'absent'
    $directory_force  = true
    $file_ensure      = 'absent'
    $job_ensure       = 'disabled'
  }
  elsif ($ensure == 'disabled') {
    $directory_ensure = 'directory'
    $directory_force  = false
    $file_ensure      = 'present'
    $job_ensure       = 'disabled'
  }
  else {
    $directory_ensure = 'directory'
    $directory_force  = false
    $file_ensure      = 'present'
    $job_ensure       = 'enabled'
  }
  file {
    "/var/lib/jenkins/jobs/$job_name":
      ensure  => $directory_ensure,
      force   => $directory_force,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0755',
      require => Package['jenkins'],
  }
  file {
    "/var/lib/jenkins/jobs/$job_name/config.xml":
      ensure  => $file_ensure,
      content => template($job_template),
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0644',
      notify  => Exec['reload-jenkins'],
  }

  if ( $ensure == 'absent' or $ensure == 'purged' ){
    if ( $dashboard_view ){
      augeas {
        "delete $job_name in $dashboard_view":
          lens    => 'Xml.lns',
          incl    => '/var/lib/jenkins/config.xml',
          context => '/files/var/lib/jenkins/config.xml',
          changes => [
            "rm ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/jobNames/string[#text=\"${job_name}\"]",
            ],
            onlyif  => "match /files/var/lib/jenkins/config.xml/${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/jobNames/string/#text[.=\"${job_name}\"] size > 0",
            require => Jenkinsjobs::Views::Dashboard[$dashboard_view],
            notify  => Exec['fix-dashboard-config'],
      }
      if ( $start_pipeline ) {
        augeas {
          "delete pipeline for $job_name in $dashboard_view":
            lens    => 'Xml.lns',
            incl    => '/var/lib/jenkins/config.xml',
            context => '/files/var/lib/jenkins/config.xml',
            changes => [
              "rm ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/${jenkinsjobs::augeas_element_portlet}[name/#text=\"${customer_name}\"]",
              ],
              onlyif  => "match /files/var/lib/jenkins/config.xml/${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/*/selectedJob/#text[.=\"${job_name}\"] size > 0",
              require => Jenkinsjobs::Views::Dashboard[$dashboard_view],
              notify  => Exec['fix-dashboard-config'],
        }
      }
    }
  }
  else{
    if ( $dashboard_view ){
      augeas {
        "add $job_name to $dashboard_view":
          lens    => 'Xml.lns',
          incl    => '/var/lib/jenkins/config.xml',
          context => '/files/var/lib/jenkins/config.xml',
          changes => [
            "set ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/jobNames/string[last()+1]/#text \"${job_name}\"",
            ],
            onlyif  => "match /files/var/lib/jenkins/config.xml/${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/jobNames/string/#text[.=\"${job_name}\"] size == 0",
            require => Jenkinsjobs::Views::Dashboard[$dashboard_view],
            notify  => Exec['fix-dashboard-config'],
      }
      if ( $start_pipeline ) {
        augeas {
          "add pipeline for $job_name to $dashboard_view":
            lens    => 'Xml.lns',
            incl    => '/var/lib/jenkins/config.xml',
            context => '/files/var/lib/jenkins/config.xml',
            changes => [
              "set ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/${jenkinsjobs::augeas_element_portlet}[last()+1]/#attribute/plugin \"build-pipeline-plugin@1.3.3\"",
              "set ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/${jenkinsjobs::augeas_element_portlet}[last()]/id/#text \"dashboard_portlet_${job_name}\"",
              "set ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/${jenkinsjobs::augeas_element_portlet}[last()]/name/#text \"${customer_name}\"",
              "set ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/${jenkinsjobs::augeas_element_portlet}[last()]/selectedJob/#text \"${job_name}\"",
              "set ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/${jenkinsjobs::augeas_element_portlet}[last()]/noOfDisplayedBuilds/#text \"1\"",
              ],
              onlyif  => "match /files/var/lib/jenkins/config.xml/${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${dashboard_view}\"]/topPortlets/*/selectedJob/#text[.=\"${job_name}\"] size == 0",
              require => Jenkinsjobs::Views::Dashboard[$dashboard_view],
              notify  => Exec['fix-dashboard-config'],
        }
      }
    }
  }
}
