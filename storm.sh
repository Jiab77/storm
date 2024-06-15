#!/usr/bin/env bash
# shellcheck disable=SC2034

# Storm - Fast Download Manager written in Bash
#
# Simple script for downloading files as fast as posssible.
#
# Made by Jiab77
#
# Supported binaries:
# - aria2
# - pget
# - lftp
# - curl
# - wget
#
# Binaries implementation has been sorted from faster to slower.
#
# Note: Only 'aria2' remains the most faster with local and remote folders.
#
# Experimental auth support based on 1fichier specs. (might change in future versions)
#
# Version 0.0.2

# Options
[[ -r $HOME/.debug ]] && set -o xtrace || set +o xtrace

# Config
DEBUG_MODE=false # Not implemented yet
VERBOSE_MODE=false
SHOW_OUTPUT=true
ENABLE_AUTH=false
USE_TOR=false # Not implemented yet
MAX_RETRY=3
MAX_TIMEOUT=30
USER_AGENT="Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535 (KHTML, like Gecko) Chrome/14 Safari/535"
FILE_LIST="links.txt"

# Internals
BIN_ARIA=$(command -v aria2c 2>/dev/null)
BIN_CURL=$(command -v curl 2>/dev/null)
BIN_LFTP=$(command -v lftp 2>/dev/null)
BIN_PGET=$(command -v pget 2>/dev/null)
BIN_WGET=$(command -v wget 2>/dev/null)
MAX_CON=$(nproc)
OUTPUT_FOLDER=$(pwd)

# Functions
function die() {
  echo -e "\nError: $1" >&2
  exit 255
}
function show_usage() {
  echo -e "\nUsage: $(basename "$0") [--auth] <url> - Download file to the current folder."
  exit
}
function get_user() {
  read -rp "Username: " ; echo -n $REPLY
}
function get_pass() {
  read -rsp "Password: " ; echo -n $REPLY
}
function get_credentials() {
  echo ; SVC_USER="$(get_user)" ; SVC_PASS="$(get_pass)"
}
function get_filename() {
  if [[ -n $BIN_CURL ]]; then
    if [[ -n $SVC_USER && -n $SVC_PASS ]]; then
      curl -k -sISL -u "$SVC_USER:$SVC_PASS" "$1" | grep -i disposition | cut -d ';' -f2 | sed -e 's/ filename="//i' -e 's/"//'
    else
      curl -sISL "$1" | grep -i disposition | cut -d ';' -f2 | sed -e 's/ filename="//i' -e 's/"//'
    fi
  elif [[ -n $BIN_WGET ]]; then
    if [[ -n $SVC_USER && -n $SVC_PASS ]]; then
      wget --no-check-certificate --http-user="$SVC_USER" --http-password="$SVC_PASS" --auth-no-challenge -Snv --method=HEAD "$1" 2>&1 | grep -i disposition | cut -d ';' -f2 | sed -e 's/ filename="//i' -e 's/"//'
    else
      wget -Snv --method=HEAD "$1" 2>&1 | grep -i disposition | cut -d ';' -f2 | sed -e 's/ filename="//i' -e 's/"//'
    fi
  else
    die "You must have at least 'curl' or 'wget' to be installed to run this script."
  fi
}
function download_file() {
  local FILE_LINK="$1"

  if [[ -n $BIN_ARIA ]]; then
    if [[ $VERBOSE_MODE == true ]]; then
      aria2c --timeout=$MAX_TIMEOUT --max-tries=$MAX_RETRY --user-agent="$USER_AGENT" --referer="$1" --max-connection-per-server="$MAX_CON" --auto-file-renaming=false --file-allocation=none "$FILE_LINK"
    else
      aria2c --timeout=$MAX_TIMEOUT --max-tries=$MAX_RETRY --user-agent="$USER_AGENT" --referer="$1" --max-connection-per-server="$MAX_CON" --auto-file-renaming=false --file-allocation=none --console-log-level=error --summary-interval=0 --download-result=hide "$FILE_LINK"
    fi
  elif [[ -n $BIN_PGET ]]; then
    local PGET_MAX_CON ; [[ $MAX_CON -gt 4 ]] && PGET_MAX_CON=4 || PGET_MAX_CON=$MAX_CON
    pget -p "$PGET_MAX_CON" --timeout $MAX_TIMEOUT --user-agent "$USER_AGENT" --referer "$1" "$FILE_LINK"
  elif [[ -n $BIN_LFTP ]]; then
    # Extracted from Synology
    # lftp --norc -c set ssl:verify-certificate false;set syno:task-id 8240;set syno:username REDACTED;set net:timeout 30;set net:max-retries 3;set http:user-agent "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535 (KHTML, like Gecko) Chrome/14 Safari/535";set xfer:log false;set syno:load-cookies '/var/services/download/8240/syno_pyload/cookie';set http:referer https://a-3.1fichier.com/p825110981;pget -c -n 4 -O /REDACTED/@download/8240 "https://1fichier.com/?bvxgd4buogk6xq8g09oo" -o "bvxgd4buogk6xq8g09oo";
    # Custom version with output folder defined and TLS certs verification disabled
    # lftp --norc -c "set ssl:verify-certificate false;set net:timeout $MAX_TIMEOUT;set net:max-retries $MAX_RETRY;set http:user-agent '$USER_AGENT';set xfer:log false;set http:referer '$1';pget -c -n $MAX_CON -O '$OUTPUT_FOLDER' '$1' -o '$2';"
    # Custom version without output folder defined and TLS certs verification disabled
    # lftp --norc -c "set ssl:verify-certificate false;set net:timeout $MAX_TIMEOUT;set net:max-retries $MAX_RETRY;set http:user-agent '$USER_AGENT';set xfer:log false;set http:referer '$1';pget -c -n $MAX_CON '$1' -o '$2';"
    # Custom version without output folder defined and TLS certs verification enabled
    lftp --norc -c "set net:timeout $MAX_TIMEOUT;set net:max-retries $MAX_RETRY;set http:user-agent '$USER_AGENT';set xfer:log false;set http:referer '$1';pget -c -n $MAX_CON '$FILE_LINK' -o '$2';"
  elif [[ -n $BIN_CURL ]]; then
    if [[ $VERBOSE_MODE == true ]]; then
      curl --connect-timeout $MAX_TIMEOUT --retry $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" -OJSL "$FILE_LINK"
    else
      curl --connect-timeout $MAX_TIMEOUT --retry $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" -OJSL --progress-bar "$FILE_LINK"
    fi
  elif [[ -n $BIN_WGET ]]; then
    if [[ $VERBOSE_MODE == true ]]; then
      wget --timeout $MAX_TIMEOUT --tries $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" --content-disposition "$FILE_LINK"
    else
      wget --timeout $MAX_TIMEOUT --tries $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" --content-disposition --quiet --show-progress "$FILE_LINK"
    fi
  else
    die "Unable to find proper backend to handle download request."
  fi
}
function download_file_with_auth() {
  local FILE_LINK="$1"

  if [[ -n $BIN_CURL ]]; then
    if [[ $VERBOSE_MODE == true ]]; then
      if [[ -n $SVC_USER && -n $SVC_PASS ]]; then
        curl -k -u "$SVC_USER:$SVC_PASS" --connect-timeout $MAX_TIMEOUT --retry $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" -SL -o "$2" "$FILE_LINK"
      else
        curl -k -u "$(get_user):$(get_pass)" --connect-timeout $MAX_TIMEOUT --retry $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" -SL -o "$2" "$FILE_LINK"
      fi
    else
      if [[ -n $SVC_USER && -n $SVC_PASS ]]; then
        curl -k -u "$SVC_USER:$SVC_PASS" --connect-timeout $MAX_TIMEOUT --retry $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" -SL -o "$2" --progress-bar "$FILE_LINK"
      else
        curl -k -u "$(get_user):$(get_pass)" --connect-timeout $MAX_TIMEOUT --retry $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" -SL -o "$2" --progress-bar "$FILE_LINK"
      fi
    fi
  elif [[ -n $BIN_WGET ]]; then
    if [[ $VERBOSE_MODE == true ]]; then
      if [[ -n $SVC_USER && -n $SVC_PASS ]]; then
        wget --method POST --no-check-certificate --http-user="$SVC_USER" --http-password="$SVC_PASS" --auth-no-challenge --timeout $MAX_TIMEOUT --tries $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" --content-disposition "$FILE_LINK"
      else
        wget --method POST --no-check-certificate --http-user="$(get_user)" --http-password="$(get_pass)" --auth-no-challenge --timeout $MAX_TIMEOUT --tries $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" --content-disposition "$FILE_LINK"
      fi
    else
      if [[ -n $SVC_USER && -n $SVC_PASS ]]; then
        wget --method POST --no-check-certificate --http-user="$SVC_USER" --http-password="$SVC_PASS" --auth-no-challenge --timeout $MAX_TIMEOUT --tries $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" --content-disposition --quiet --show-progress "$FILE_LINK"
      else
        wget --method POST --no-check-certificate --http-user="$(get_user)" --http-password="$(get_pass)" --auth-no-challenge --timeout $MAX_TIMEOUT --tries $MAX_RETRY --user-agent "$USER_AGENT" --referer "$1" --content-disposition --quiet --show-progress "$FILE_LINK"
      fi
    fi
  else
    die "Unable to find proper backend to handle download request."
  fi
}
function show_output() {
  ls -halF --color=always "$1"
}
function init_download() {
  if [[ $ENABLE_AUTH == true && -z $SVC_USER && -z $SVC_PASS ]]; then
    echo -e "\nGathering user credentials..."
    get_credentials
  fi

  echo -e "\n\nGathering file info..."
  local DOWNLOADED_FILENAME ; DOWNLOADED_FILENAME="$(get_filename "$1")"
  [[ -z $DOWNLOADED_FILENAME ]] && DOWNLOADED_FILENAME="$(basename "$1")"
  if [[ $# -eq 3 ]]; then
    echo -e "\nDownloading file [$2 / $3] - $DOWNLOADED_FILENAME...\n"
  else
    echo -e "\nDownloading '$DOWNLOADED_FILENAME'...\n"
  fi

  if [[ $ENABLE_AUTH == false ]]; then
    download_file "$1" "$DOWNLOADED_FILENAME"
  else
    download_file_with_auth "$1" "$DOWNLOADED_FILENAME"
  fi

  if [[ $SHOW_OUTPUT == true ]]; then
    echo -e "\n\nDownload finished. Showing output folder...\n"
    show_output "$OUTPUT_FOLDER"
  else
    echo -e "\n\nDownload finished. Showing file properties...\n"
    show_output "$DOWNLOADED_FILENAME"
  fi
}
function download_list() {
  echo -ne "\nLoading list file..."

  local TOTAL_LINES ; TOTAL_LINES=$(wc -l < "$1")
  local CURRENT_LINE=0

  echo " $TOTAL_LINES links loaded."

  if [[ $ENABLE_AUTH == true ]]; then
    echo -e "\nGathering user credentials for the whole list..."
    get_credentials
  fi

  if [[ $TOTAL_LINES -ne 0 ]]; then
    while read -r link; do
      init_download "$link" $((++CURRENT_LINE)) "$TOTAL_LINES"
    done < "$1"
  fi

  [[ $CURRENT_LINE == "$TOTAL_LINES" ]] && echo -e "\nFinished." || echo -e "\nStopped."
}

# Checks
[[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && show_usage
[[ $# -eq 2 && $1 == "--auth" ]] && ENABLE_AUTH=true && shift
[[ -z $BIN_ARIA && -z $BIN_PGET && -z $BIN_LFTP && -n $BIN_CURL && -z $BIN_WGET ]] && die "You must install 'aria2', 'pget' or 'lftp' for more performances and 'curl' or 'wget' as fallback to run this script."

# Main
if [[ "$(basename "$1")" == "$FILE_LIST" ]]; then
  time download_list "$1"
else
  time init_download "$1"
fi
