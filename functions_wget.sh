#!/bin/bash

# Authenticates credentials against Central and returns the cookie jar file name. USERNAME must
# be set before calling this function. The user will be prompted for the password by curl.
#   USERNAME="foo"
#   COOKIE_JAR=$(startSession)
startSession() {
    # Authentication to XNAT and store cookies in cookie jar file
    local COOKIE_JAR=.cookies-$(date +%Y%M%d%s).txt
    wget --http-user="${USERNAME}" --ask-password --keep-session-cookies --save-cookies=${COOKIE_JAR} --auth-no-challenge --no-check-certificate --output-document=jsession.txt --quiet "https://central.xnat.org/data/JSESSION" 
    rm -f jsession.txt
    echo ${COOKIE_JAR}
}

# Downloads a resource from a URL and stores the results to the specified path. The first parameter
# should be the destination path and the second parameter should be the URL.
download() {
    local OUTPUT=${1}
    local URL=${2}
    wget --load-cookies ${COOKIE_JAR} --auth-no-challenge --no-check-certificate --output-document=${OUTPUT} "${URL}"
}

# Ends the user session.
endSession() {
    # Delete the JSESSION token - "log out"
    wget --load-cookies ${COOKIE_JAR} --auth-no-challenge --no-check-certificate --output-document=jsession.txt --quiet --method=DELETE "https://central.xnat.org/data/JSESSION"
    rm -f jsession.txt ${COOKIE_JAR}
}

