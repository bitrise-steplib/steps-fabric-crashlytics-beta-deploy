#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# load bash utils
source "${THIS_SCRIPT_DIR}/bash_utils/utils.sh"
source "${THIS_SCRIPT_DIR}/bash_utils/formatted_output.sh"

# init the formatted output
echo "" >> "${formatted_output_file_path}"

# ------------------------------
# --- Error Cleanup

function finalcleanup {
  echo "-> finalcleanup"
  local fail_msg="$1"

  write_section_to_formatted_output "# Error"
  if [ ! -z "${fail_msg}" ] ; then
    write_section_to_formatted_output "**Error Description**:"
    write_section_to_formatted_output "${fail_msg}"
  fi
  write_section_to_formatted_output "*See the logs for more information*"
}

function CLEANUP_ON_ERROR_FN {
  local err_msg="$1"
  finalcleanup "${err_msg}"
}
set_error_cleanup_function CLEANUP_ON_ERROR_FN


# ------------------------------
# --- Main

#
# - Required Params
if [ -z "${api_key}" ] ; then
	finalcleanup '* Required input `$api_key` not provided!'
	exit 1
fi
if [ -z "${build_secret}" ] ; then
	finalcleanup '* Required input `$build_secret` not provided!'
	exit 1
fi
if [ -z "${ipa_path}" ] ; then
	finalcleanup '* Required input `$ipa_path` not provided!'
	exit 1
fi
if [ ! -f "${ipa_path}" ] ; then
	finalcleanup "* IPA path defined but the file does not exist at path: ${ipa_path}"
	exit 1
fi	

write_section_to_formatted_output "# Submitting..."

#
# - Release Notes: save to file
CONFIG_release_notes_pth="${HOME}/app_release_notes.txt"
printf "%s" "${release_notes}" > "${CONFIG_release_notes_pth}"

#
# - Optional params

if [ ! -z "${email_list}" ] ; then
	_param_emails="-emails \"${email_list}\""
fi
if [ ! -z "${group_aliases_list}" ] ; then
	_param_groups="-groupAliases ﻿\"${group_aliases_list}\""
fi

CONFIG_is_send_notifications="YES"
if [[ "${notification}" == "No" ]] ; then
	CONFIG_is_send_notifications="NO"
fi


#
# - Submit
print_and_do_command_exit_on_error "${THIS_SCRIPT_DIR}/Crashlytics.framework/submit" \
	"${api_key}" "${build_secret}" \
	-ipaPath "${ipa_path}" \
	-notesPath "${CONFIG_release_notes_pth}" \
	-notifications "${CONFIG_is_send_notifications}" \
	${_param_emails} \
	${_param_groups}


#
# - Success Summary
write_section_to_formatted_output "# Success"

write_section_to_formatted_output "## Notified testers"
if [[ "${CONFIG_is_send_notifications}" == "NO" ]] ; then
	echo_string_to_formatted_output "* You disabled notification sending for this deploy"
else
	if [ -z "${email_list}" ] ; then
		echo_string_to_formatted_output "* No email list provided"
	else
		echo_string_to_formatted_output "* Emails: ${email_list}"
	fi
	if [ -z "${group_aliases_list}" ] ; then
		echo_string_to_formatted_output "* No groups provided"
	else
		echo_string_to_formatted_output "* Groups: ${group_aliases_list}"
	fi
fi

write_section_to_formatted_output "## Release Notes"
write_section_to_formatted_output "${release_notes}"
