# shell include for common functions etc

function log() {
    echo "[`date +%T.%N|cut -c1-12`] $*"
}

