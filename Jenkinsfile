#!groovy

@Library('katsdpjenkins') _
katsdp.killOldJobs()
katsdp.setDependencies(['ska-sa/katsdpdockerbase/master'])
katsdp.standardBuild()
katsdp.mail('sdpdev+katsdpBASE@ska.ac.za')
