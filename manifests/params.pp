# = Class: jenkinsjobs::params
#
# Description of jenkinsjobs::params
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
class jenkinsjobs::params {
  ## Copy paste snippets:
  # template("${module_name}/template.erb")
  # source => "puppet:///modules/${module_name}/file"

  if ( ! $augeas_element_portlet ) {
    $augeas_element_portlet = 'au.com.centrumsystems.hudson.plugin.buildpipeline.dashboard.BuildPipelineDashboard'
  }
  if ( ! $augeas_prefix_dashboard ) {
    $augeas_prefix_dashboard = 'hudson/views/hudson.plugins.view.dashboard.Dashboard'
  }
}

