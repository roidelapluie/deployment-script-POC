#!/bin/bash
FIRST_JOB="$1"
APPEND="$2"
[ -z "$APPEND" ] && exit 2
[ -d "/var/lib/jenkins/jobs/${jobname}" ] || exit 3

rename_job(){
    jobname="$1"

    echo "* RENAMING " $jobname to ${jobname}${APPEND}

    # Remove existing jobs if any

    [ -d "/var/lib/jenkins/jobs/${jobname}${APPEND}" ] && echo "** REMOVING EXISTING JOB" && rm -rf "/var/lib/jenkins/jobs/${jobname}${APPEND}"

    # Copy jobs files to a new location

    cp -r "/var/lib/jenkins/jobs/${jobname}" "/var/lib/jenkins/jobs/${jobname}${APPEND}"

    # Give jenkins full access

    chown jenkins: -R "/var/lib/jenkins/jobs/${jobname}${APPEND}"

    # Finds the next jobs to clone
    find_next_jobs "$jobname"
}

find_next_jobs(){
    jobname="$1"

    # Search for the next projects in the config.xml

    projects=$(cat /var/lib/jenkins/jobs/${jobname}/config.xml|
        egrep '<(projects|downstreamProjectNames)>'|
        awk -F '<|>' '{print $3}'|
        sed 's/, /\n/g'|
        grep -v ^$)


    # Print the next projects

    echo "** NEXT PROJECTS:" $projects

    # Replace next projects in the current configuration and rename them
    for project in $projects
    do
        sed -i "/<\(projects\|downstreamProjectNames\)>/s/\([> ]\)${project}\([<,]\)/\1${project}${APPEND}\2/" -i "/var/lib/jenkins/jobs/${jobname}${APPEND}/config.xml"
        rename_job $project
    done

}

rename_job $1
