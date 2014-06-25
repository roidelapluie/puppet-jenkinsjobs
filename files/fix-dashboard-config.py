#!/usr/bin/python
# This script will re-order the scripts the the jenkins dashboard views
# If the jobs are sorted alphabetically, all the jobs do not appear
# inside the view.
# This script fixes this issues.
# USAGE: fix-dashboard-config.py /var/lib/jenkins/config.xml
import sys
try:
    from lxml import etree
except ImportError:
    sys.stderr.write("You need lxml to use this script\n")
    exit(4)


if __name__ == '__main__':
    try:
        filename = sys.argv[1]
    except IndexError:
        sys.stderr.write("You must pass the Jenkins configuration file as argument\n")
        exit(1)

    try:
        doc = etree.parse(filename)
    except IOError:
        sys.stderr.write("error accessing the configuration file\n")
        exit(2)

    for parent in doc.xpath('//hudson/views/hudson.plugins.view.dashboard.Dashboard/jobNames'): # Search for parent elements
        children = parent.getchildren()
        sorted_children = sorted(children,key=lambda x: x.text)
        parent.clear()
        for child in sorted_children:
            parent.append(child)

    try:
        doc.write(filename)
    except IOError:
        sys.stderr.write("error writing the configuration file\n")
        exit(3)
