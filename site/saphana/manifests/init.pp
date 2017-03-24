# Class: saphana
# ===========================
#
# Full description of class saphana here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'saphana':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2017 Your name here, unless otherwise noted.
#
class saphana {

#create the HDB_BatchInst file
# disable NUMA balancing
file { '/root/HDB_BatchInst':
  ensure => file,
  content => epp('saphana/HDB_BatchInst.epp')
}

#run the actual install
exec { "install_start_hana":
     command	=> "hdblcm -b --configfile /root/HDB_BatchInst",
     cwd => '/mnt/sapbits/HANA_51051151/DATA_UNITS/HDB_LCM_LINUX_X86_64',
     path    => '/bin:/usr/bin:/usr/sbin',
     unless  => 'sudo -u hdbadm bash -l /usr/sap/HDB/HDB00/HDB info 2>&1 | grep hdbnameserver',
     require => File['/root/HDB_BatchInst'],     
}

}
