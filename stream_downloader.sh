#!/bin/bash

STREAM_URL="https://content.jwplatform.com/manifests/yp34SRmf.m3u8"
DOWNLOAD_LOCATION="${HOME}/Downloads"
OUTPUT_FILE_NAME="eSatsang_$(date +'%Y%m%d%H%M%S%Z')"

function f_check_stream_available() {
    while true
    do
        [ $(curl -o /dev/null -I -L -s -w "%{http_code}" "${STREAM_URL}") -eq 200 ] && return 0
        sleep 60
    done
}

if f_check_stream_available; then

    # Create download location if it does not exists
    if [ ! -d ${DOWNLOAD_LOCATION} ]; then
        mkdir -p ${DOWNLOAD_LOCATION}
    fi

    # Download the stream
    # -i is for input URL/PATH
    # copy everything being received (-c copy)
    # re-encode the stream using bitstream filter (-bsf:a aac_adtstoasc)
    ffmpeg -i "${STREAM_URL}" -c copy -bsf:a aac_adtstoasc "${DOWNLOAD_LOCATION}/${OUTPUT_FILE_NAME}.mp4"
fi
