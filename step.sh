#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	options=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for option in "${options[@]}" ; do
		if [ "${option}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
	fi
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
echo_details "* api_key: ***"
echo_details "* build_secret: ***"
echo_details "* ipa_path: $ipa_path"
echo_details "* dsym_path: $dsym_path"
echo_details "* service_info_plist_path: $service_info_plist_path"
echo_details "* email_list: $email_list"
echo_details "* group_aliases_list: $group_aliases_list"
echo_details "* notification: $notification"
echo_details "* release_notes: $release_notes"

echo

if [ -z "${dsym_path}" ] && [ -z "${ipa_path}" ] ; then
	echo_fail "No ipa_path nor dsym_path defined"
fi

if [ ! -z "${ipa_path}" ] ; then
	validate_required_input "api_key" $api_key
	validate_required_input "build_secret" $build_secret
fi

if [ ! -z "${dsym_path}" ] ; then
	if [ ! -f "${dsym_path}" ] ; then
		echo_fail "DSYM path defined but the file does not exist at path: ${dsym_path}"
	fi

	if [ -z "${api_key}"] && [ -z "${service_info_plist_path}" ]; then
		echo_fail "Either `Fabric: API Key` (api_key) or `GoogleService-Info.plist path` (service_info_plist_path) needs to specified for dSYM upload."
	fi

	if [ -z "${service_info_plist_path}" ] && [ ! -f "${service_info_plist_path}" ]; then 
		echo_fail "GoogleService-Info.plist path specified, but file does not exist at path: ${service_info_plist_path}"
	fi
fi

if [ ! -z "${ipa_path}" ] ; then
	validate_required_input "api_key" $api_key
	validate_required_input "build_secret" $build_secret

	if [ ! -f "${ipa_path}" ] ; then
		echo_fail "IPA path defined but the file does not exist at path: ${ipa_path}"
	fi

	# - Release Notes: save to file
	CONFIG_release_notes_pth="${HOME}/app_release_notes.txt"
	printf "%s" "${release_notes}" > "${CONFIG_release_notes_pth}"

	# - Optional params
	if [ -n "${email_list}" ] ; then
		_param_emails="-emails \"${email_list}\""
	fi

	if [ -n "${group_aliases_list}" ] ; then
		_param_groups="-groupAliases ﻿\"${group_aliases_list}\""
	fi

	CONFIG_is_send_notifications="YES"
	if [[ "${notification}" == "No" ]] ; then
		CONFIG_is_send_notifications="NO"
	fi


	# - Submit IPA
	echo_info "Submitting IPA..."

	submit_cmd="${THIS_SCRIPT_DIR}/Fabric/submit"
	submit_cmd="$submit_cmd \"${api_key}\" \"${build_secret}\""
	submit_cmd="$submit_cmd -ipaPath \"${ipa_path}\""
	submit_cmd="$submit_cmd -notesPath \"${CONFIG_release_notes_pth}\""
	submit_cmd="$submit_cmd -notifications \"${CONFIG_is_send_notifications}\""
	submit_cmd="$submit_cmd ${_param_emails} ${_param_groups}"

	echo_details "$submit_cmd"
	echo

	eval "$submit_cmd"

	if [ $? -eq 0 ] ; then
		echo_done "Success"
	else
		echo_fail "Fail"
	fi
fi 

# - Submit DSYM
if [ ! -z "${dsym_path}" ] ; then
  echo_info "Submitting DSYM..."

  dsym_cmd="${THIS_SCRIPT_DIR}/Fabric/upload-symbols"

  if [ ! -z "${service_info_plist_path}"]; then
	dsym_cmd="${dsym_cmd -gsp \"${service_info_plist_path}\""
  else
  	dsym_cmd="${dsym_cmd} -a \"${api_key}\""
  fi

  dsym_cmd="${dsym_cmd} -p ios"
  dsym_cmd="${dsym_cmd} \"${dsym_path}\""

  echo_details "$dsym_cmd"
  echo

  eval "$dsym_cmd"

  if [ $? -eq 0 ] ; then
    echo_done "Success"
  else
    echo_fail "Fail"
  fi
fi
