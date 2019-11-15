#!/bin/bash
#
# Digital Ocean Droplet resize
#

function print_usage() {
  echo "Usage: $0 DROPLET_NAME NEW_SIZE"
  echo "Example:"
  echo "$0 mydroplet_name.fqdn c-8"
  echo "$0 mydroplet_name.fqdn s-1vcpu-1gb"
  return 0
}

function wait_for_task() {
  local DROPLET_ID=$1
  [[ -z ${DROPLET_ID} ]] && { echo "Function wait_for_task: Expecting droplet id as argument";return 1; }

  local TASK_ID=$2
  [[ -z ${TASK_ID} ]] && { echo "Function wait_for_task: Expecting task id as argument";return 1; }

  while true
  do
    local TASK_STATUS=$(doctl compute droplet-action get ${DROPLET_ID} --action-id ${TASK_ID} \
      |grep -v 'ID'|awk '{print $2}')
    
    echo "TASK Status is: ${TASK_STATUS}"

    if [[ ${TASK_STATUS} == 'completed' ]]
    then
      return 0
    else
      sleep 10s
    fi
  done
}

function poweroff_droplet() {
  local DROPLET_ID=$1
  [[ -z ${DROPLET_ID} ]] && { echo "Function poweroff: Expecting droplet id as argument";return 1; }

  # Check droplet status
  local DROPLET_STATUS=$(doctl compute droplet get ${DROPLET_ID} --template "{{ .Status}}")
  [[ -z ${DROPLET_STATUS} ]] && { echo "Function poweroff: Could not obtain droplet status";return 1; }
  
  echo "DROPLET Status is: ${DROPLET_STATUS}"
  
  if [[ ${DROPLET_STATUS} == "off" ]]
  then
    echo "Droplet status is off. Doing nothing."
    return 0
  elif [[ ${DROPLET_STATUS} == "active" ]]
  then
    echo "Droplet status is active. Proceeding with power-off."
    local TASK_ID=$(doctl compute droplet-action power-off ${DROPLET_ID} \
      |grep -v 'ID'|awk '{print $1}')

    echo "Poweroff Task ID is: ${TASK_ID}"

    if wait_for_task ${DROPLET_ID} ${TASK_ID}
    then
      return 0
    else
      echo "Something went wrong while monitoring task_status, please manually check."
      return 1
    fi
  else
    echo "Unknown status of droplet. Doing nothing."
    return 1
  fi
}

function poweron_droplet() {
  local DROPLET_ID=$1
  [[ -z ${DROPLET_ID} ]] && { echo "Function poweron: Expecting droplet id as argument";return 1; }

  local TASK_ID=$(doctl compute droplet-action power-on ${DROPLET_ID} \
    |grep -v 'ID'|awk '{print $1}')
  
  echo "Poweron Task ID is ${TASK_ID}"

  if wait_for_task ${DROPLET_ID} ${TASK_ID} 
  then
    # Verify that the droplet is active
    local DROPLET_STATUS=$(doctl compute droplet get ${DROPLET_ID} --template "{{ .Status}}")

    echo "Droplet Status is: ${DROPLET_STATUS}"
  
    if [[ ${DROPLET_STATUS} == "active" ]]
    then
      return 0
    else
      echo "Something went wrong. Droplet status is not active after power-on."
      return 1
    fi

  fi
}

function resize_droplet() {
  local DROPLET_ID=$1
  [[ -z ${DROPLET_ID} ]] && { echo "Function resize_droplet: Expecting droplet id as argument";return 1; }

  local NEW_SIZE=$2
  [[ -z ${NEW_SIZE} ]] && { echo "Function resize_droplet: Expecting new size as argument";return 1; }

  local TASK_ID=$(doctl compute droplet-action resize ${DROPLET_ID} --size ${NEW_SIZE} \
    |grep -v 'ID'|awk '{print $1}')
  
  echo "Resize Task ID is ${TASK_ID}"
  
  if wait_for_task ${DROPLET_ID} ${TASK_ID}
  then
    return 0
  fi
  
}

function main() {
  
  local DROPLET_ID=$1
  [[ -z ${DROPLET_ID} ]] && { echo "Function main: Expecting droplet id as argument"; return 1; }

  local NEW_SIZE=$2
  [[ -z ${NEW_SIZE} ]] && { echo "Function main: Expecting new size as argument"; return 1; }

  # Power Off the Droplet
  echo "Powering off droplet ${DROPLET_NAME} - ${DROPLET_ID}"
  poweroff_droplet ${DROPLET_ID}

  # Resize Droplet to desired size
  echo "Resizing ${DROPLET_NAME} - ${DROPLET_ID} to ${NEW_SIZE}"
  resize_droplet ${DROPLET_ID} ${NEW_SIZE}

  # Power On the Droplet
  echo "Powering on droplet ${DROPLET_NAME} - ${DROPLET_ID} "
  poweron_droplet ${DROPLET_ID}

  # List the resized
  echo "The resized droplet is..."
  doctl compute droplet list ${DROPLET_NAME} \
    --format ID,Name,PublicIPv4,Memory,VCPUs,Disk,Region,Status
}
###
#
###
DROPLET_NAME=$1
[[ -z ${DROPLET_NAME} ]] && { echo "Expecting droplet name as argument"; print_usage; exit 1; }

NEW_SIZE=$2
[[ -z ${NEW_SIZE} ]] && { echo "Expecting new size as argument"; print_usage; exit 1; }

# Find the droplet id of the given host name
DROPLET_ID=$(doctl compute droplet list ${DROPLET_NAME} --no-header --format "ID")
[[ -z ${DROPLET_ID} ]] && { echo "Could not find droplet id."; exit 1; }

main ${DROPLET_ID} ${NEW_SIZE}
exit
