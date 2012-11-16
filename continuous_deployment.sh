#!/bin/bash
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"


usage()
{
cat <<END
usage:
    $0 -f package_file -p package_manager [-g graphite_host -x graphite_prefix]

    -f is a file containing the packages that needs to be updated,
       in the form package[:version[:repository]]
    -p is the package manager (yum or apt)
    -g graphite host (optionnal)
    -x graphite prefix (optionnal)
    -h shows this message

END
}

apt_check_version(){
    PACKAGE="$1"
    VERSION="$2"
    dpkg -l $PACKAGE|
    grep ^ii|
    awk -v ver="${VERSION}" 'BEGIN{exitcode=1} $3 == ver {exitcode=0} END{exit exitcode}'
}
apt_update_package(){
    PACKAGE="$1"
    VERSION="$2"
    if [ -z ${VERSION} ]
    then
        apt-get -y upgrade "${PACKAGE}"
    else
        apt-get -y install "${PACKAGE}=${VERSION}"
        apt_check_version "${PACKAGE}" "${VERSION}"
    fi
}

apt_clean_repository(){
    apt-get update
}

yum_check_version(){
    PACKAGE="$1"
    VERSION="$2"
    rpm -qi "${PACKAGE}-${VERSION}"
}

yum_update_package(){
    PACKAGE="$1"
    VERSION="$2"
    if [ -z ${VERSION} ]
    then
        yum update -y "${PACKAGE}"
    else
        yum update -y "${PACKAGE}-${VERSION}"
        yum_check_version "${PACKAGE}" "${VERSION}"
    fi
}

yum_clean_repository(){
    REPOSITORY="$1"
    if [ -z "$REPOSITORY" ]
    then
        yum clean all
    else
        yum clean all --disablerepo='*' --enablerepo="$REPOSITORY"
    fi
}

while getopts "hp:f:g:x:" OPTION
do
    case ${OPTION} in
        h)
            usage
            exit 0;;
        p)
            if [ "x${OPTARG}" == 'xapt' ] || [ "x${OPTARG}" == 'xyum' ]
            then
                PACKAGE_MANAGER=${OPTARG}
            else
                (
                echo "Package manager not supported"
                usage
                )>&2
                exit 1
            fi;;
        x)
            GRAPHITE_PREFIX="${OPTARG}";;
        g)
            GRAPHITE_HOST="${OPTARG}";;
        f)
            PACKAGE_FILE="${OPTARG}";;
    esac
done

if [ -z "${PACKAGE_MANAGER}" ]
then
    (
    echo "You must specify a package manager (-p)."
    usage
    )>&2
    exit 2
fi

if [ -z "${PACKAGE_FILE}" ]
then
    (
    echo "You must specify a file (-f)."
    usage
    )>&2
    exit 3
fi

if [ ! -f "${PACKAGE_FILE}" ]
then
    exit 0
else
    TMPFILE="$(mktemp)"
    mv "${PACKAGE_FILE}" "${TMPFILE}"
fi

for package in $(cut -d: -f1 < "${TMPFILE}"|sort -u )
do
    grep "^$package:" "${TMPFILE}"|
    sort -t : -k 2 -rn|
    head -n 1
done|while IFS=: read PACKAGE VERSION REPOSITORY
do
    "${PACKAGE_MANAGER}_clean_repository" "${REPOSITORY}"
    if "${PACKAGE_MANAGER}_update_package" "${PACKAGE}" "${VERSION}"
    then
        if [ ! -z "${GRAPHITE_PREFIX}" ] && [ ! -z "${GRAPHITE_HOST}" ]
        then
            echo "${GRAPHITE_PREFIX}.${PACKAGE} 1 $(date +%s)" > "/dev/tcp/${GRAPHITE_HOST}/2003"
        fi
    else
        echo "${PACKAGE}:${VERSION}:${REPOSITORY}" >> "${PACKAGE_FILE}"
    fi
done

rm -f "${TMPFILE}"


