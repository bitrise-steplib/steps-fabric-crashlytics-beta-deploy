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
# --- Utils - Keychain

function keychain_fn {
  if [[ "$1" == "add" ]] ; then
    # LC_ALL: required for tr, for more info: http://unix.stackexchange.com/questions/45404/why-cant-tr-read-from-dev-urandom-on-osx
    # export KEYCHAIN_PASSPHRASE="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

    # Create the keychain
    if [ ! -f "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}" ] ; then
    	print_and_do_command_exit_on_error security -v create-keychain -p "${KEYCHAIN_PASSPHRASE}" "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"
    fi

    # Unlock keychain
    print_and_do_command_exit_on_error security -v list-keychains -s "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"
    print_and_do_command_exit_on_error security -v list-keychains
    print_and_do_command_exit_on_error security -v unlock-keychain -p "${KEYCHAIN_PASSPHRASE}" "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"
    print_and_do_command_exit_on_error security -v set-keychain-settings -lut 72000 "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"
    print_and_do_command_exit_on_error security -v default-keychain -s "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"

    # Import to keychain
    print_and_do_command_exit_on_error security -v import "${CERTIFICATE_PATH}" -k "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}" -P "${STEP_CERT_ACTIVATOR_CERTIFICATE_PASSPHRASE}" -A
  elif [[ "$1" == "remove" ]] ; then
    print_and_do_command_exit_on_error security -v delete-keychain "${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"
  fi
}

print_and_do_command_exit_on_error mkdir -p "${STEP_CERT_ACTIVATOR_CERTIFICATES_DIR}"

# --- Get certificate
write_section_to_formatted_output "# Downloading Certificate..."
export CERTIFICATE_PATH="${STEP_CERT_ACTIVATOR_CERTIFICATES_DIR}/Certificate.p12"
print_and_do_command curl -Lfso "${CERTIFICATE_PATH}" "${STEP_CERT_ACTIVATOR_CERTIFICATE_URL}"
cert_curl_result=$?
if [ ${cert_curl_result} -ne 0 ]; then
  echo " (i) First download attempt failed - retry..."
  sleep 5
  print_and_do_command_exit_on_error curl -Lfso "${CERTIFICATE_PATH}" "${STEP_CERT_ACTIVATOR_CERTIFICATE_URL}"
fi
echo "CERTIFICATE_PATH: ${CERTIFICATE_PATH}"
if [[ ! -f "${CERTIFICATE_PATH}" ]]; then
  finalcleanup "CERTIFICATE_PATH: File not found - failed to download"
  exit 1
else
  echo " -> CERTIFICATE_PATH: OK"
fi

# LC_ALL: required for tr, for more info: http://unix.stackexchange.com/questions/45404/why-cant-tr-read-from-dev-urandom-on-osx
keychain_pass="${STEP_CERT_ACTIVATOR_KEYCHAIN_PSW}"
export KEYCHAIN_PASSPHRASE="${keychain_pass}"
keychain_fn "add"


# Get identities from certificate
identity_from_cert=$(security find-certificate -a ${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH} | grep -Ei '"labl"<blob>=".*"' | grep -oEi '=".*"' | grep -oEi '[^="]+' | head -n 1)

write_section_to_formatted_output "# Success"
write_section_to_formatted_output "Certificate Activated"
echo_string_to_formatted_output "* Identity: ${identity_from_cert}"
echo_string_to_formatted_output "* Keychain: ${STEP_CERT_ACTIVATOR_KEYCHAIN_PATH}"
echo_string_to_formatted_output "* Certificate stored to file: ${CERTIFICATE_PATH}"
