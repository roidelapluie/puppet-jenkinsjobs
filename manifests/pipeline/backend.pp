define jenkinsjobs::pipeline::backend (
  $git_repository,
  $ensure          = 'present',
  $customer_name   = $title,
  $debian_slave    = undef,
  $dashboard_view  = undef,
  $qa_url          = undef,
  $qa_node         = undef,
  $qa_db           = undef,
  $qa_password     = undef,
){

  Jenkinsjobs::Job{
    ensure          => $ensure,
    git_repository  => $git_repository,
    customer_name   => $customer_name,
    assigned_node   => $debian_slave,
    dashboard_view  => $dashboard_view,
    qa_db           => $qa_db,
    qa_password     => $qa_password,
    qa_url          => $qa_url,
    package_name    => "mds-$customer_name",
    vhost_docroot   => "$customer_name",
    custom_modules  => 'sites/all/modules',
    job_type        => 'drupal',
  }

  Jenkinsjobs::Promotion{
    ensure         => $ensure,
    customer_name  => $customer_name,
    assigned_node  => $debian_slave,
    packaging_job  => "mds-backend-build-${customer_name}",
    package_name   => "mds-$customer_name",
    vhost_docroot  => "$customer_name",
  }

  jenkinsjobs::job{
    "mds-backend-checkout-$customer_name":
      job_template   => 'jenkinsjobs/jobs/checkout.erb',
      next_job       => "mds-backend-syntax-$customer_name",
      start_pipeline => true,
  }

  jenkinsjobs::job{
    "mds-backend-syntax-$customer_name":
      job_template => 'jenkinsjobs/jobs/syntax.erb',
      next_job     => "mds-backend-style-$customer_name",
  }

  jenkinsjobs::job{
    "mds-backend-style-$customer_name":
      job_template => 'jenkinsjobs/jobs/style.erb',
      next_job     => "mds-backend-build-$customer_name, mds-backend-build-$customer_name-centos",
  }

  jenkinsjobs::job{
    "mds-backend-build-$customer_name-centos":
      job_template  => 'jenkinsjobs/jobs/build-centos.erb',
      next_job      => "mds-backend-deploy-to-datacenter5-$customer_name-centos",
  }

  jenkinsjobs::job{
    "mds-backend-build-$customer_name":
      job_template => 'jenkinsjobs/jobs/build.erb',
      next_job     => "mds-backend-metadata-$customer_name",
  }

  jenkinsjobs::job{
    "mds-backend-metadata-$customer_name":
      job_template => 'jenkinsjobs/jobs/metadata.erb',
      previous_job => "mds-backend-build-$customer_name",
      next_job     => "mds-backend-apt-repository-sync-$customer_name",
  }

  jenkinsjobs::job{
    "mds-backend-apt-repository-sync-$customer_name":
      job_template => 'jenkinsjobs/jobs/apt-repository-sync.erb',
      next_job     => "mds-backend-deploy-to-datacenter5-$customer_name",
  }

  jenkinsjobs::job{
    "mds-backend-deploy-to-datacenter5-$customer_name":
      job_template => 'jenkinsjobs/jobs/deploy.erb',
      next_job     => "mds-backend-tests-in-datacenter5-$customer_name",
      targets      => {
        'mds01'    => 'server01.datacenter5.mds',
        'mds03'    => 'server03.datacenter5.mds',
      },
  }


  jenkinsjobs::job{
    "mds-backend-deploy-to-datacenter5-$customer_name-centos":
      job_template => 'jenkinsjobs/jobs/deploy.erb',
      next_job     => "mds-backend-tests-in-datacenter5-$customer_name-centos",
      targets      => {
        'mds05'    => 'server05.datacenter5.mds',
        'mds07'    => 'server07.datacenter5.mds',
      },
  }

  jenkinsjobs::job{
    "mds-backend-tests-in-datacenter5-$customer_name":
      job_template  => 'jenkinsjobs/jobs/tests-datacenter5.erb',
      next_job      => "mds-backend-promote-$customer_name",
      assigned_node => $qa_node,
  }

  #added - check if assigned node should be server07?
  jenkinsjobs::job{
    "mds-backend-tests-in-datacenter5-$customer_name-centos":
      job_template  => 'jenkinsjobs/jobs/tests-datacenter5.erb',
      next_job      => "mds-backend-promote-$customer_name-centos",
      assigned_node => $qa_node,
  }

  jenkinsjobs::job{
    "mds-backend-promote-$customer_name":
      job_template => 'jenkinsjobs/jobs/promote.erb',
      promotions   => ["deploy-$customer_name-to-datacenter1-uat",
                      "deploy-$customer_name-to-datacenter2-uat",
                      "deploy-$customer_name-to-datacenter2-prod",
                      "deploy-$customer_name-to-datacenter4-prod",
                      "deploy-$customer_name-to-datacenter3-prod",
                      "deploy-$customer_name-to-datacenter1-prod"],
  }

  #centos promotion
  jenkinsjobs::job{
    "mds-backend-promote-$customer_name-centos":
      job_template => 'jenkinsjobs/jobs/promote.erb',
      promotions   => ["deploy-$customer_name-to-datacenter1-uat-centos",
                      "deploy-$customer_name-to-datacenter1-prod-centos"],
  }



  $targets = hiera("mediasalsa_backend_promotion_$customer_name")

  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter1-uat":
      job_name           => "mds-backend-promote-$customer_name",
      promotion_template => 'jenkinsjobs/promotions/uat.erb',
      debian_repo_name   => 'mediamosa-uat',
      targets            => $targets['datacenter1-uat'],
  }

  #centos promotion
  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter1-uat-centos":
      job_name           => "mds-backend-promote-$customer_name-centos",
      promotion_template => 'jenkinsjobs/promotions/uat_centos.erb',
      centos_repo_name   => 'mds-uat-mediasalsa',
      targets            => $targets['datacenter1-uat-centos'],
      packaging_job      => "mds-backend-build-$customer_name-centos",
  }

  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter4-prod":
      job_name           => "mds-backend-promote-$customer_name",
      promotion_template => 'jenkinsjobs/promotions/uat.erb',
      required_promotion => "deploy-$customer_name-to-datacenter1-uat",
      debian_repo_name   => 'mediamosa-production',
      targets            => $targets['datacenter4-prod'],
  }

  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter1-prod":
      job_name           => "mds-backend-promote-$customer_name",
      promotion_template => 'jenkinsjobs/promotions/uat.erb',
      required_promotion => "deploy-$customer_name-to-datacenter1-uat",
      debian_repo_name   => 'mediamosa-production',
      targets            => $targets['datacenter1-prod'],
  }

  #centos promotion
  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter1-prod-centos":
      job_name           => "mds-backend-promote-$customer_name-centos",
      promotion_template => 'jenkinsjobs/promotions/uat_centos.erb',
      required_promotion => "deploy-$customer_name-to-datacenter1-uat-centos",
      centos_repo_name   => 'mds-prod-mediasalsa',
      targets            => $targets['datacenter1-prod-centos'],
      packaging_job      => "mds-backend-build-$customer_name-centos",
  }

  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter3-prod":
      job_name           => "mds-backend-promote-$customer_name",
      promotion_template => 'jenkinsjobs/promotions/uat.erb',
      required_promotion => "deploy-$customer_name-to-datacenter1-uat",
      debian_repo_name   => 'mediamosa-production',
      targets            => $targets['datacenter3-prod'],
  }

  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter2-uat":
      job_name           => "mds-backend-promote-$customer_name",
      promotion_template => 'jenkinsjobs/promotions/uat.erb',
      debian_repo_name   => 'mediamosa-uat',
      targets            => $targets['datacenter2-uat'],
  }


  jenkinsjobs::promotion {
    "deploy-$customer_name-to-datacenter2-prod":
      job_name           => "mds-backend-promote-$customer_name",
      promotion_template => 'jenkinsjobs/promotions/uat.erb',
      required_promotion => "deploy-$customer_name-to-datacenter2-uat",
      debian_repo_name   => 'mediamosa-production',
      targets            => $targets['datacenter2-prod'],
  }

}
