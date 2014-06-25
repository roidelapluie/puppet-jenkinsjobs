define jenkinsjobs::pipeline::symfony (
  $git_repository,
  $ensure          = 'present',
  $customer_name   = $title,
  $debian_slave    = undef,
  $dashboard_view  = undef,
  $targets     = {},
){

  $vhost_docroot = "symfony-${customer_name}"

  Jenkinsjobs::Job{
    ensure          => $ensure,
    git_repository  => $git_repository,
    customer_name   => $customer_name,
    assigned_node   => $debian_slave,
    dashboard_view  => $dashboard_view,
    package_name    => "symfony-${customer_name}",
    vhost_docroot   => $vhost_docroot,
    job_type        => 'symfony',
  }

  jenkinsjobs::job{
    "symfony-checkout-$customer_name":
      job_template   => 'jenkinsjobs/jobs/checkout.erb',
      next_job       => "symfony-syntax-$customer_name",
      start_pipeline => true,
  }

  jenkinsjobs::job{
    "symfony-syntax-$customer_name":
      job_template => 'jenkinsjobs/jobs/syntax.erb',
      next_job     => "symfony-style-$customer_name",
  }

  jenkinsjobs::job{
    "symfony-style-$customer_name":
      job_template => 'jenkinsjobs/jobs/style.erb',
      next_job     => "symfony-phpunit-$customer_name",
  }

  jenkinsjobs::job{
    "symfony-phpunit-$customer_name":
      job_template => 'jenkinsjobs/jobs/phpunit.erb',
      next_job     => "symfony-package-and-pulp-$customer_name"
  }

  jenkinsjobs::job{
    "symfony-package-and-pulp-$customer_name":
      job_template => 'jenkinsjobs/jobs/build-rpm.erb',
      next_job     => "symfony-deploy-to-dev-$customer_name"
  }

  jenkinsjobs::job{
    "symfony-deploy-to-dev-$customer_name":
      job_template => 'jenkinsjobs/jobs/deploy.erb',
      targets      => $targets['dev'],
  }

  #  jenkinsjobs::job{
  #    "mds-frontend-build-$customer_name":
  #      job_template => 'jenkinsjobs/jobs/build.erb',
  #      next_job     => "mds-frontend-metadata-$customer_name",
  #  }
  #
  #  jenkinsjobs::job{
  #    "mds-frontend-metadata-$customer_name":
  #      job_template => 'jenkinsjobs/jobs/metadata.erb',
  #      previous_job => "mds-frontend-build-$customer_name",
  #      next_job     => "mds-frontend-apt-repository-sync-$customer_name",
  #  }
  #
  #  jenkinsjobs::job{
  #    "mds-frontend-apt-repository-sync-$customer_name":
  #      job_template => 'jenkinsjobs/jobs/apt-repository-sync.erb',
  #      next_job     => "mds-frontend-deploy-to-datacenter5-$customer_name",
  #  }
  #
  #  jenkinsjobs::job{
  #    "mds-frontend-deploy-to-datacenter5-$customer_name":
  #      job_template => 'jenkinsjobs/jobs/deploy-to-datacenter5.erb',
  #      next_job     => "mds-frontend-promote-$customer_name",
  #      targets      => { 'mds01' => 'server01.datacenter5.mds', },
  #  }
  #
  #  jenkinsjobs::job{
  #    "mds-frontend-promote-$customer_name":
  #      job_template => 'jenkinsjobs/jobs/promote.erb',
  #      promotions   => ["deploy-$customer_name-frontend-to-uat",
  #                      "deploy-$customer_name-frontend-to-datacenter4-prod",
  #                      "deploy-$customer_name-frontend-to-datacenter1-prod"],
  #  }
  #
  #  if 'datacenter1-uat' in $targets {
  #    jenkinsjobs::promotion {
  #      "deploy-$customer_name-frontend-to-uat":
  #        promotion_template => 'jenkinsjobs/promotions/uat.erb',
  #        debian_repo_name   => 'mediamosa-uat',
  #        targets            => $targets['datacenter1-uat'],
  #    }
  #
  #    if 'datacenter4-prod' in $targets {
  #      jenkinsjobs::promotion {
  #        "deploy-$customer_name-frontend-to-datacenter4-prod":
  #          promotion_template => 'jenkinsjobs/promotions/uat.erb',
  #          required_promotion => "deploy-$customer_name-frontend-to-uat",
  #          debian_repo_name   => 'mediamosa-production',
  #          targets            => $targets['datacenter4-prod'],
  #      }
  #    }
  #    else {
  #      jenkinsjobs::promotion {
  #        "deploy-$customer_name-frontend-to-datacenter4-prod":
  #          ensure => 'absent',
  #      }
  #    }
  #
  #    if 'datacenter1-prod' in $targets {
  #      jenkinsjobs::promotion {
  #        "deploy-$customer_name-frontend-to-datacenter1-prod":
  #          promotion_template => 'jenkinsjobs/promotions/uat.erb',
  #          required_promotion => "deploy-$customer_name-frontend-to-uat",
  #          debian_repo_name   => 'mediamosa-production',
  #          targets            => $targets['datacenter1-prod'],
  #      }
  #    }
  #    else {
  #      jenkinsjobs::promotion {
  #        "deploy-$customer_name-frontend-to-datacenter1-prod":
  #          ensure => 'absent',
  #      }
  #    }
  #  }
}
