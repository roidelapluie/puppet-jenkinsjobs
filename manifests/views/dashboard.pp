define jenkinsjobs::views::dashboard {
  augeas {
    "dashboard view $title":
      lens    => 'Xml.lns',
      incl    => '/var/lib/jenkins/config.xml',
      context => '/files/var/lib/jenkins/config.xml',
      changes => [
        "set ${jenkinsjobs::augeas_prefix_dashboard}[last()+1]/owner/#attribute/class \"hudson\"",
        "set ${jenkinsjobs::augeas_prefix_dashboard}[last()]/owner/#attribute/reference \"../../..\"",
        "set ${jenkinsjobs::augeas_prefix_dashboard}[last()]/includeStdJobList/#text \"true\"",
        "set ${jenkinsjobs::augeas_prefix_dashboard}[last()]/name/#text \"${title}\"",
      ],
      onlyif  => "match /files/var/lib/jenkins/config.xml/hudson/views/*/name/#text[.=\"${title}\"] size == 0",
      notify  => Exec['reload-jenkins'],
  } ->
  augeas {
    "delete empty topPortlets in $title":
      lens    => 'Xml.lns',
      incl    => '/var/lib/jenkins/config.xml',
      context => '/files/var/lib/jenkins/config.xml',
      changes => [
        "rm ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${title}\"]/topPortlets",
      ],
      onlyif  => "match ${jenkinsjobs::augeas_prefix_dashboard}[name/#text=\"${title}\"]/topPortlets[.=\"#empty\"] size > 0",
  }
}
