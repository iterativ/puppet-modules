#
# ITerativ GmbH
# http://www.iterativ.ch/
#
# Copyright (c) 2012 ITerativ GmbH. All rights reserved.
#
# Created on Sep 21, 2012
# @author: maersu <me@maersu.ch>

import xmlrpclib
import pip
from itertools import izip_longest
import sys
import getopt

class CheckForUpdates(object):

    def compare_version(self, version_local, version_remote):
        
        status = 0
        for l, r in izip_longest(version_local.split('.'), version_remote.split('.')):     
            if l is None:
                status = 1
                break
            elif r is None:
                status = 2
                break
            
            if l.isdigit() and r.isdigit():
                l = int(l)
                r = int(r)
            if l < r:
                status = 1
                break
            elif l > r:
                status = 2
                break
        if status == 1:
            return '\x1b[0;32m%s available\x1b[0;39m' % version_remote
        elif status == 2:
            return 'ahead (%s >= %s)' % (version_local, version_remote)
        else:
            return 'up to date'
 
    def run(self, packages):
        pypi = xmlrpclib.ServerProxy('http://pypi.python.org/pypi')
        
        print 'check for updates (local)'
        if len(packages) > 0:
            print '  packages:', ', '.join(packages)
        print
         
        for dist in pip.get_installed_distributions():
            
            if len(packages) == 0 or dist.project_name in packages:           
                available = pypi.package_releases(dist.project_name)
                if not available:
                    # Try to capitalize pkg name
                    available = pypi.package_releases(dist.project_name.capitalize())
                if not available:
                    # Try to lower
                    available = pypi.package_releases(dist.project_name.lower())
               
                if not available:
                    msg = 'no releases at pypi'
                else:
                    msg = self.compare_version(dist.version, available[0])
                print '%s\t%s' % ('{dist.project_name}=={dist.version}'.format(dist=dist), msg)
        print 

if __name__ == "__main__":

    try:
        opts, args = getopt.getopt(sys.argv[1:], "h", ["help"])
    except getopt.error, msg:
        print msg
        print "for help use --help"
        sys.exit(2)
    # process options
    for o, a in opts:
        if o in ("-h", "--help"):
            print "Check if there are some package updates available (current activated env)"
            print "   usage: %s [package1 ... packageN]" % sys.argv[0]
            sys.exit(0)
    
    CheckForUpdates().run(list(args))