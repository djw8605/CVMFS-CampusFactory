#!/bin/sh

die() {
  echo 2>&1 "$@"
  exit 1
}

#if ! [ -x test.sh ]; then
#  echo "You must run this test from the directory containing test.h"
#  exit 1
#fi
pwd
rm -rf var
mkdir var || die "Failed to create test/var"

TEST_DIR=`pwd`/var
ls
ls ../../
cat << EOF > glidein_config
ADD_CONFIG_LINE_SOURCE TEST_DIR/../../../add_config_line.source
PROXY_URL cache01.hep.wisc.edu:3128
CONDOR_VARS_FILE TEST_DIR/condor_vars.lst
GLIDECLIENT_GLIDEIN_PARROT TEST_DIR/parrot
GLIDECLIENT_GLIDEIN_CMS_SITECONF TEST_DIR/cms_siteconf
EOF
cat ../../add_config_line.source
. ../../add_config_line.source
export glidein_config=$TEST_DIR/glidein_config
sed < glidein_config > $glidein_config "s|TEST_DIR|$TEST_DIR|g" || die "Failed to create test/var/glidein_config"
cat $glidein_config

mkdir $TEST_DIR/parrot
tar x -C $TEST_DIR/parrot -f `pwd`/../../parrot.tgz || die "Failed to extract parrot"

#mkdir $TEST_DIR/cms_siteconf
#tar x -C $TEST_DIR/cms_siteconf -f `pwd`/../cms_siteconf.tgz || die "Failed to extract cms_siteconf"

touch $TEST_DIR/condor_vars.lst

../../parrot_setup $TEST_DIR/glidein_config || die "parrot_setup failed"
#./parrot_cms_setup $TEST_DIR/glidein_config || die "parrot_cms_setup failed"


#cd $TEST_DIR

#export _CONDOR_SCRATCH_DIR=`pwd`
#export _CONDOR_SLOT=1
#export _CONDOR_JOB_AD=.jobad
#echo RequiresCVMFS=True > $_CONDOR_JOB_AD

export CVMFS_OSG_APP=`grep -i "^CVMFS_OSG_APP " $glidein_config | awk '{print $2}'`
export OSG_APP=$CVMFS_OSG_APP
export GLIDEIN_PARROT=`grep -i "^GLIDEIN_PARROT " $glidein_config | awk '{print $2}'`
export GLIDEIN_PARROT_OPTIONS=`grep -i "^GLIDEIN_PARROT_OPTIONS " $glidein_config | awk '{$1=""; print $0}'`

#sh ../../cvmfs_job_wrapper test -d $CVMFS_OSG_APP || die "cvmfs_job_wrapper failed to find $CVMFS_OSG_APP"

#sh ../../cvmfs_job_wrapper cp $CVMFS_OSG_APP/cmssoft/cms/SITECONF/local/PhEDEx/storage.xml . || die "cvmfs_job_wrapper failed"

#diff cms_siteconf/SITECONF/local/PhEDEx/storage.xml storage.xml || die "storage.xml copied from within parrot does not match expected"

# workaround for difficulty passing PARROT_CVMFS_REPO via STARTER_JOB_ENVIRONMENT
    source ${GLIDEIN_PARROT}/setup.sh

    # If possible (i.e. not using glexec), share the tmp area between
    # jobs that run in this slot.
    # Also avoid using a shared area if this is an ssh_to_job session or
    # any other hook that may run at the same time as the job.

    parrot_tmp="${GLIDEIN_PARROT}/tmp${_CONDOR_SLOT}"
    if ! mkdir -p "$parrot_tmp" >& /dev/null || ! [ -w "$parrot_tmp" ] || ! [ -z "$_CONDOR_JOB_PIDS" ]; then
      parrot_tmp="${_CONDOR_SCRATCH_DIR}/parrot_tmp.$$"
    fi

    # point OSG_APP into cvmfs
    if [ "$CVMFS_OSG_APP" != "" ]; then
      export LOCAL_OSG_APP="$OSG_APP"
      export OSG_APP="$CVMFS_OSG_APP"
    fi

    # As of parrot 3.4.0, parrot causes ssh_to_job to fail, so
    # avoid using parrot when _CONDOR_JOB_PIDS is non-empty.
    # (That's how we guess that this is an ssh_to_job session.)

    if [ -z "$_CONDOR_JOB_PIDS" ]; then
      # Note that since we exec the job here, wrappers that come after
      # this one are ignored.
      exec "$GLIDEIN_PARROT/parrot_run" -t "$parrot_tmp" $GLIDEIN_PARROT_OPTIONS $JOB_PARROT_OPTIONS "$@"
    fi

#exec "$@"
echo "Success"

