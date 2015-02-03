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
if [ -z "${STEP_CRASHLYTICS_API_KEY}" ] ; then
	finalcleanup '* Required input `$STEP_CRASHLYTICS_API_KEY` not provided!'
	exit 1
fi
if [ -z "${STEP_CRASHLYTICS_BUILD_SECRET}" ] ; then
	finalcleanup '* Required input `$STEP_CRASHLYTICS_BUILD_SECRET` not provided!'
	exit 1
fi
if [ -z "${STEP_CRASHLYTICS_IPA_PATH}" ] ; then
	finalcleanup '* Required input `$STEP_CRASHLYTICS_IPA_PATH` not provided!'
	exit 1
fi
if [ ! -f "${STEP_CRASHLYTICS_IPA_PATH}" ] ; then
	finalcleanup "* IPA path defined but the file does not exist at path: ${STEP_CRASHLYTICS_IPA_PATH}"
	exit 1
fi	

#
# - Activate the Certificate
(
	print_and_do_command_exit_on_error cd "${THIS_SCRIPT_DIR}/cert_activator"
	print_and_do_command_exit_on_error bash step.sh
)
fail_if_cmd_error "Failed to Activate the Certificate Private Key!"


write_section_to_formatted_output "# Submitting..."

#
# - Release Notes: save to file
CONFIG_release_notes_pth="${HOME}/app_release_notes.txt"
printf "%s" "${STEP_CRASHLYTICS_RELEASE_NOTES}" > "${CONFIG_release_notes_pth}"


if [ ! -z "${STEP_CRASHLYTICS_EMAIL_LIST}" ] ; then
	_param_emails='-emails "${STEP_CRASHLYTICS_EMAIL_LIST}"'
fi
if [ ! -z "${STEP_CRASHLYTICS_GROUP_ALIASES_LIST}" ] ; then
	_param_groups='-groupAliases ﻿"${STEP_CRASHLYTICS_GROUP_ALIASES_LIST}"'
fi

#
# - Submit
print_and_do_command_exit_on_error "${THIS_SCRIPT_DIR}/Crashlytics.framework/submit" \
	"${STEP_CRASHLYTICS_API_KEY}" "${STEP_CRASHLYTICS_BUILD_SECRET}" \
	-ipaPath "${STEP_CRASHLYTICS_IPA_PATH}" \
	-notesPath "${CONFIG_release_notes_pth}" \
	${_param_emails} \
	${_param_groups}


#
# - Success Summary
write_section_to_formatted_output "# Success"

write_section_to_formatted_output "## Release Notes"
write_section_to_formatted_output "${STEP_CRASHLYTICS_RELEASE_NOTES}"