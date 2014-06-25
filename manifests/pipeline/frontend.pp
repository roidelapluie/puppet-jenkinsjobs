define jenkinsjobs::pipeline::frontend (
  $git_repository,
  $ensure          = 'present',
  $customer_name   = $title,
  $debian_slave    = undef,
  $dashboard_view  = undef,
  $vhost_docroot   = undef,
  $targets     = {},
){

  $_vhost_docroot = $vhost_docroot ? {
    undef   => "frontend-${customer_name}",
    default => $vhost_docroot,
  }

  Jenkinsjobs::Job{
    ensure         => $ensure,
    git_repository => $git_repository,
    customer_name  => $customer_name,
    assigned_node  => $debian_slave,
    dashboard_view => $dashboard_view,
    package_name   => "mds-frontend-${customer_name}",
    vhost_docroot  => $_vhost_docroot,
    custom_modules => 'sites/all/modules/custom',
    job_type       => 'drupal',
  }

  Jenkinsjobs::Promotion{
    ensure         => $ensure,
    customer_name  => $customer_name,
    assigned_node  => $debian_slave,
    packaging_job  => "mds-frontend-build-${customer_name}",
    package_name   => "mds-frontend-${customer_name}",
    vhost_docroot  => $_vhost_docroot,
    job_name       => "mds-frontend-promote-${customer_name}",
  }

  jenkinsjobs::job{
    "mds-frontend-checkout-${customer_name}":
      job_template   => 'jenkinsjobs/jobs/checkout.erb',
      next_job       => "mds-frontend-syntax-${customer_name}",
      start_pipeline => true,
  }

  jenkinsjobs::job{
    "mds-frontend-syntax-${customer_name}":
      job_template => 'jenkinsjobs/jobs/syntax.erb',
      next_job     => "mds-frontend-style-${customer_name}",
  }

  jenkinsjobs::job{
    "mds-frontend-style-${customer_name}":
      job_template => 'jenkinsjobs/jobs/style.erb',
      next_job     => "mds-frontend-build-${customer_name}, mds-frontend-build-${customer_name}-centos",
  }

  jenkinsjobs::job{
    "mds-frontend-build-${customer_name}-centos":
      job_template => 'jenkinsjobs/jobs/build-centos.erb',
      next_job     =>  "mds-frontend-deploy-to-datacenter5-${customer_name}-centos",
  }

  jenkinsjobs::job{
    "mds-frontend-build-${customer_name}":
      job_template => 'jenkinsjobs/jobs/build.erb',
      next_job     => "mds-frontend-metadata-${customer_name}",
  }

  jenkinsjobs::job{
    "mds-frontend-metadata-${customer_name}":
      job_template => 'jenkinsjobs/jobs/metadata.erb',
      previous_job => "mds-frontend-build-${customer_name}",
      next_job     => "mds-frontend-apt-repository-sync-${customer_name}",
  }

  jenkinsjobs::job{
    "mds-frontend-apt-repository-sync-${customer_name}":
      job_template => 'jenkinsjobs/jobs/apt-repository-sync.erb',
      next_job     => "mds-frontend-deploy-to-datacenter5-${customer_name}",
  }

  jenkinsjobs::job{
    "mds-frontend-deploy-to-datacenter5-${customer_name}":
      job_template => 'jenkinsjobs/jobs/deploy.erb',
      next_job     => "mds-frontend-promote-${customer_name}",
      targets      => { 'mds01' => 'server01.datacenter5.mds', },
  }

  jenkinsjobs::job{
    "mds-frontend-deploy-to-datacenter5-${customer_name}-centos":
      job_template => 'jenkinsjobs/jobs/deploy.erb',
      next_job     => "mds-frontend-promote-${customer_name}-centos",
      targets      => { 'mds05' => 'server05.datacenter5.mds', },
  }

  jenkinsjobs::job{
    "mds-frontend-promote-${customer_name}":
      job_template => 'jenkinsjobs/jobs/promote.erb',
      promotions   => ["deploy-${customer_name}-frontend-to-datacenter1-uat",
                      "deploy-${customer_name}-frontend-to-datacenter4-prod",
                      "deploy-${customer_name}-frontend-to-datacenter2-prod",
                      "deploy-${customer_name}-frontend-to-datacenter2-uat",
                      "deploy-${customer_name}-frontend-to-datacenter1-prod"],
  }

  jenkinsjobs::job{
    "mds-frontend-promote-${customer_name}-centos":
      job_template => 'jenkinsjobs/jobs/promote.erb',
      promotions   => ["deploy-${customer_name}-frontend-to-datacenter1-uat-centos",
                      "deploy-${customer_name}-frontend-to-datacenter1-prod-centos"],
  }

  if 'datacenter1-uat' in $targets {
    jenkinsjobs::promotion {
      "deploy-${customer_name}-frontend-to-datacenter1-uat":
        promotion_template => 'jenkinsjobs/promotions/uat.erb',
        debian_repo_name   => 'mediamosa-uat',
        targets            => $targets['datacenter1-uat'],
    }

    #we added parameter centos_repo_name to avoid confusion - we should probably just rename debian_repo_name parameter
    jenkinsjobs::promotion {
      "deploy-${customer_name}-frontend-to-datacenter1-uat-centos":
        promotion_template => 'jenkinsjobs/promotions/uat_centos.erb',
        centos_repo_name   => 'mds-uat-mediasalsa',
        targets            => $targets['datacenter1-uat-centos'],
        packaging_job      => "mds-frontend-build-${customer_name}-centos",
        job_name           => "mds-frontend-promote-${customer_name}-centos",
    }


    if 'datacenter4-prod' in $targets {
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter4-prod":
          promotion_template => 'jenkinsjobs/promotions/uat.erb',
          required_promotion => "deploy-${customer_name}-frontend-to-datacenter1-uat",
          debian_repo_name   => 'mediamosa-production',
          targets            => $targets['datacenter4-prod'],
      }
    }
    else {
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter4-prod":
          ensure => 'absent',
      }
      # jenkinsjobs::promotion {
      #   "deploy-${customer_name}-frontend-to-datacenter4-prod-centos":
      #     ensure => 'absent',
      # }
    }

    if 'datacenter1-prod' in $targets {
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter1-prod":
          promotion_template => 'jenkinsjobs/promotions/uat.erb',
          required_promotion => "deploy-${customer_name}-frontend-to-datacenter1-uat",
          debian_repo_name   => 'mediamosa-production',
          targets            => $targets['datacenter1-prod'],
      }

      #we added parameter centos_repo_name to avoid confusion - we should probably just rename debian_repo_name parameter
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter1-prod-centos":
          promotion_template => 'jenkinsjobs/promotions/uat_centos.erb',
          required_promotion => "deploy-${customer_name}-frontend-to-datacenter1-uat-centos",
          centos_repo_name   => 'mds-prod-mediasalsa',
          targets            => $targets['datacenter1-prod'],
          packaging_job      => "mds-frontend-build-${customer_name}-centos",
          job_name           => "mds-frontend-promote-${customer_name}-centos",
      }

    }
    else {
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter1-prod":
          ensure => 'absent',
      }

        jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter1-prod-centos":
          ensure => 'absent',
      }
    }
  }

  if 'datacenter2-uat' in $targets {
    jenkinsjobs::promotion {
      "deploy-${customer_name}-frontend-to-datacenter2-uat":
        promotion_template => 'jenkinsjobs/promotions/uat.erb',
        debian_repo_name   => 'mediamosa-uat',
        targets            => $targets['datacenter2-uat'],
    }

    if 'datacenter2-prod' in $targets {
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter2-prod":
          promotion_template => 'jenkinsjobs/promotions/uat.erb',
          required_promotion => "deploy-${customer_name}-frontend-to-datacenter2-uat",
          debian_repo_name   => 'mediamosa-production',
          targets            => $targets['datacenter2-prod'],
      }
    }
    else {
      jenkinsjobs::promotion {
        "deploy-${customer_name}-frontend-to-datacenter2-prod":
          ensure => 'absent',
      }
    }

  }
}
