#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Info:
# 	Miroslav Vidovic
# 	log4bash.sh
# 	14.08.2016.-11:13:42
# -----------------------------------------------------------------------------
# Forked from:
#     log4bash - Makes logging in Bash scripting suck less
#     Copyright (c) Fred Palmer
#     Licensed under the MIT license
#     http://github.com/fredpalmer/log4bash
# -----------------------------------------------------------------------------
# Description:
#
# Usage:
#
# -----------------------------------------------------------------------------
# Script:

# Fail on first error
set -e

# Useful global variables that users may wish to reference
SCRIPT_ARGS="$@"
SCRIPT_NAME="$0"
SCRIPT_NAME="${SCRIPT_NAME#\./}"
SCRIPT_NAME="${SCRIPT_NAME##/*/}"
SCRIPT_BASE_DIR="$(cd "$( dirname "$0")" && pwd )"

# This should probably be the right way - didn't have time to experiment though
# declare INTERACTIVE_MODE="$([ tty --silent ] && echo on || echo off)"
if [ "$INTERACTIVE_MODE" == "" ]; then
	declare INTERACTIVE_MODE=$([ "$(uname)" == "Linux" ] && echo "on" || echo "off")
fi

#------------------------------------------------------------------------------
# Begin Help Section

HELP_TEXT=""

# This function is called in the event of an error.
# Scripts which source this script may override by defining their own "usage" function
usage() {
    echo -e "${HELP_TEXT}";
    exit 1;
}

# End Help Section
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Begin LogZ.io setup

LOGZ_SCHEME=${LOGZ_SCHEME:-http}
LOGZ_HOST=${LOGZ_HOST:-listener.logz.io}
LOGZ_PORT=${LOGZ_PORT:-8070}
LOGZ_URL="$LOGZ_SCHEME://$LOGZ_HOST:$LOGZ_PORT?token=$LOGZ_TOKEN"
LOGZ_META_type=${LOGZ_META_type:-bash}
LOGZ_ENABLE=${LOGZ_ENABLE:-no}

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Begin Logging Section
if [[ "${INTERACTIVE_MODE}" == "off" ]]
then
    # Then we don't care about log colors
    declare LOG_DEFAULT_COLOR=""
    declare LOG_ERROR_COLOR=""
    declare LOG_INFO_COLOR=""
    declare LOG_SUCCESS_COLOR=""
    declare LOG_WARN_COLOR=""
    declare LOG_DEBUG_COLOR=""
else
    declare LOG_DEFAULT_COLOR="\033[0m"
    declare LOG_ERROR_COLOR="\033[1;31m"
    declare LOG_INFO_COLOR="\033[1m"
    declare LOG_SUCCESS_COLOR="\033[1;32m"
    declare LOG_WARN_COLOR="\033[1;33m"
    declare LOG_DEBUG_COLOR="\033[1;34m"
fi

# This function scrubs the output of any control characters used in colorized output
# It's designed to be piped through with text that needs scrubbing.  The scrubbed
# text will come out the other side!
prepare_log_for_nonterminal() {
    # Essentially this strips all the control characters for log colors
    sed "s/[[:cntrl:]]\[[0-9;]*m//g"
}

log() {
    local log_text="$1"
    local log_level="$2"
    local log_color="$3"

	LOGZ_META_level=$log_level

    # Default level to "info"
    [[ -z ${log_level} ]] && log_level="INFO";
    [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

	if [ "$1" != "@" ]; then
    	echo -e "${log_color}[$(date +"%x %X")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}";
		log_logzio "${log_level,,}" "${log_text}"
	else
		set +e
		# If there are no parameters read from stdin
		while read log_text; do
    		echo -e "${log_color}[$(date +"%x %X")] [${log_level}] ${log_text} ${LOG_DEFAULT_COLOR}";
			log_logzio "${log_level,,}" "${log_text}"
		done
		set -e
	fi

    return 0;
}

log_info()      {
	log "${@:-@}";
}

# Using espeak on Linux
log_speak() {
    if type -P espeak >/dev/null
    then
        local easier_to_say="$1";
        espeak -ven+f3 -k5 -s150 "$1"
    fi
    return 0;
}

log_success()   { log "${1:-@}" "SUCCESS" "${LOG_SUCCESS_COLOR}"; }
log_error()     { log "${1:-@}" "ERROR" "${LOG_ERROR_COLOR}"; }
log_warning()   { log "${1:-@}" "WARNING" "${LOG_WARN_COLOR}"; }
log_debug()     { log "${1:-@}" "DEBUG" "${LOG_DEBUG_COLOR}"; }
log_captains()  {
    if type -P figlet >/dev/null;
    then
        figlet -f slant -w 120 "$1";
    else
        log "$1";
    fi

    log_speak "$1";

    return 0;
}

log_campfire() {
    # This function performs a campfire notification with the arguments passed to it
    if [[ -z ${CAMPFIRE_API_AUTH_TOKEN} || -z ${CAMPFIRE_NOTIFICATION_URL} ]]
    then
        log_warning "CAMPFIRE_API_AUTH_TOKEN and CAMPFIRE_NOTIFICATION_URL must be set in order log to campfire."
        return 1;
    fi

    local campfire_message="
    {
        \"message\": {
            \"type\":\"TextMessage\",
            \"body\":\"$@\"
        }
    }"

    curl                                                            \
        --write-out "\r\n"                                          \
        --user ${CAMPFIRE_API_AUTH_TOKEN}:X                         \
        --header 'Content-Type: application/json'                   \
        --data "${campfire_message}"                                \
        ${CAMPFIRE_NOTIFICATION_URL}
    return $?;
}

log_logzio() {
	if [ "$LOGZ_ENABLE" != "yes" ]; then
		return 0
	fi

	# This function performs a logz.io dump with the arguments passed to it
	if [[ -z ${LOGZ_TOKEN} ]]; then
		log_warning "LOGZ_TOKEN must be set in order log to logz.io."
		return 1;
	fi

	LEVEL="$1"
	shift

	LOGZ_AWK=/tmp/.logz.awk
	LOGZ_JSON=$(mktemp)

	if [ ! -f $LOGZ_AWK ]; then
		cat <<EOS > /tmp/.logz.awk
BEGIN { ret=""; first=1 }
/^LOGZ_META_/ {
	if (first==1)
	 	first = 0;
	else
		ret = ret ", ";
	key=\$1
	gsub(/LOGZ_META_/, "", key);
	val=\$2
	ret = ret "\"" key "\": \"" val "\""
}
END { print ret }
EOS
	fi

	local logz_meta=$(set | awk -F "=" -f $LOGZ_AWK)
	cat <<EOS > $LOGZ_JSON
{ "message": "$@", "level": "$LEVEL", "meta": { $logz_meta } }
EOS

	cat $LOGZ_JSON | curl -X POST ${LOGZ_URL} --header 'Content-Type: application/json' --data-binary @-

	rm $LOGZ_JSON

    return $?;
}

# End Logging Section
#-------------------------------------------------------------------------------
