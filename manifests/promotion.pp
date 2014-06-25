define jenkinsjobs::promotion(
  $customer_name,
  $job_name,
  $promotion_template = 'jenkinsjobs/promotions/none.erb',
  $promotion_name     = $title,
  $ensure             = 'present',
  $required_promotion = undef,
  $assigned_node      = undef,
  $package_name       = undef,
  $packaging_job      = undef,
  $targets            = undef,
  $debian_repo_name   = undef,
  $centos_repo_name   = undef,
  $vhost_docroot      = undef,
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
    "/var/lib/jenkins/jobs/$job_name/promotions/$promotion_name":
      ensure  => $directory_ensure,
      force   => $directory_force,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0755',
      require => Package['jenkins'],
  }
  file {
    "/var/lib/jenkins/jobs/$job_name/promotions/$promotion_name/config.xml":
      ensure  => $file_ensure,
      content => template($promotion_template),
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0644',
      require => File["/var/lib/jenkins/jobs/$job_name/promotions/$promotion_name"],
      notify  => Exec['reload-jenkins'],
  }

}
