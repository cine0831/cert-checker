#!/bin/bash
# -*-Shell-script-*-
#
#/**
# * Title    : certification checker
# * Auther   : Alex, Lee
# * Created  : 2019-07-12
# * Modified : 2019-08-08
# * E-mail   : cine0831@gmail.com
#**/
#
#set -e
#set -x

HTTPS_PORT=("443" "444")
SMTPS_PORT=("25")
CERT_HOME="/usr/mgmt/cert-checker"
CERT_LOG="${CERT_HOME}/logs"
TIMEOUT="5"
server_date=$(date +"%Y-%m-%d %H:%M:%S")

# CERT_LOG directory check
if [ ! -d ${CERT_LOG} ]; then
    mkdir ${CERT_LOG}
elif [ -f ${CERT_LOG} ]; then
    unlink ${CERT_LOG}
    mkdir ${CERT_LOG}
fi

# CURL PATH
if [ -f /usr/local/library_package/curl/bin/curl ]; then
    CURL="/usr/local/library_package/curl/bin/curl"
elif [ -f /usr/local/curl/bin/curl ]; then
    CURL="/usr/local/curl/bin/curl"
elif [ -f /usr/local/bin/curl ]; then
    CURL="/usr/local/bin/curl"
else
    CURL="/usr/bin/curl"
fi

function usage {
    echo "Usage: $0 -d [domain name] -p [HTTPS or SMTPS] -t [local or remote]"
    exit 1;
}

function get_certification {
    local x=""
    local y=""
    local HOST="$1"
    local PROTOCOL="$2"
    local TARGET="$3"

    # HTTPS Protocol
    if [[ "${PROTOCOL}" = "HTTPS" ]]; then
        for i in "${HTTPS_PORT[@]}"; do
            if [ "${TARGET}" = "local" ]; then
                listen_port=$(netstat -nptl | grep '^tcp' | awk '{print $4}' | grep "\:${i}$" | sed -e 's/^\:\://g' | cut -d":" -f 2)
            else
                listen_port="443"
            fi

            if [ "${i}" = "${listen_port}" ]; then
                x=$(${CURL} -v --insecure --tlsv1 -m ${TIMEOUT} --cert-status --url "https://$HOST:${i}" 2>&1 | grep 'subject:' | awk '{$1="\b";print}' | awk '{print $NF}' | sed -e 's/CN\=//g')
                y=$(${CURL} -v --insecure --tlsv1 -m ${TIMEOUT} --cert-status --url "https://$HOST:${i}" 2>&1 | grep 'expire date:' | awk '{$1="";print}' | sed -e 's/^\ expire date: //g')
            fi

            if [[ "${x}" = "" ]] && [[ "${y}" = "" ]]; then
                break
            else
                y=`date --date="${y}" +"%Y-%m-%d"`

                echo "Hostname: "${HOSTNAME}" / Domain: ${HOST} / CN: ${x} / notAfter: ${y}" 
cat << EOF >> ${CERT_LOG}/${PROTOCOL}-cert.json
{ "host": "${HOSTNAME}", "time": "${server_date}", "domain": "${HOST}", "CN": "${x}", "notAfter": "${y}", "port": ${listen_port} }
EOF
            fi

            x=""
            y=""
        done
    fi

    # SMTP Protocol
    if [[ "${PROTOCOL}" = "SMTPS" ]]; then
        for i in "${SMTPS_PORT[@]}"; do
            if [ "${TARGET}" = "local" ]; then
                listen_port=$(netstat -nptl | grep '^tcp' | awk '{print $4}' | grep "\:${i}$" | sed -e 's/^\:\://g' | cut -d":" -f 2)
            else
                listen_port="25"
            fi

            if [ "${i}" = "${listen_port}" ]; then
                x=$(${CURL} -v --insecure --tlsv1 -m ${TIMEOUT} --ssl --cert-status --url "smtp://$HOST:${i}" 2>&1 | grep 'subject:' | awk '{$1="\b";print}' | awk '{print $NF}' | sed -e 's/CN\=//g')
                y=$(${CURL} -v --insecure --tlsv1 -m ${TIMEOUT} --ssl --cert-status --url "smtp://$HOST:${i}" 2>&1 | grep 'expire date:' | awk '{$1="";print}' | sed -e 's/^\ expire date: //g')
            fi

            if [[ "${x}" = "" ]] && [[ "${y}" = "" ]]; then
                break
            else
                y=`date --date="${y}" +"%Y-%m-%d"`

                echo "Hostname: "${HOSTNAME}" / Domain: ${HOST} / CN: ${x} / notAfter: ${y}" 
cat << EOF >> ${CERT_LOG}/${PROTOCOL}-cert.json
{ "host": "${HOSTNAME}", "time": "${server_date}", "domain": "${HOST}", "CN": "${x}", "notAfter": "${y}", "port": ${listen_port} }
EOF
            fi

            x=""
            y=""
        done
    fi
}

while getopts "h:d:p:t:" arg; do
    case ${arg} in
       d) 
          if [[ -z ${OPTARG} ]] || [[ "${OPTARG}" = "localhost" ]]; then
              domain=${HOSTNAME}
          else
              domain=${OPTARG}
          fi
          ;;
       p) protocol=${OPTARG}
          ;;
       t) if [[ -z ${OPTARG} ]] || [[ "${OPTARG}" = "local" ]]; then
              target="local"
          elif [[ "${OPTARG}" = "remote" ]]; then
              target=${OPTARG}
          else
              usage
          fi
          ;;
       h|*)
          usage
          ;;
    esac
done

if [[ "${protocol}" = "HTTPS" ]] || [[ "${protocol}" = "SMTPS" ]]; then
    get_certification "${domain}" "${protocol}" "${target}"
else
    echo "${OPTARG} unsupport protocol."
    usage
fi
