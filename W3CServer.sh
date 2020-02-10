#!/bin/bash

usage() {
#    echo "usage: $0 startme|stopme|configureme" >&2
    echo "usage: $0 startme|stopme" >&2
}

startme() {
    echo "starting ..."
    screen -d -m -S serverCore bash -c 'cd server/server-core  && go build && ./server-core'
    sleep 5s
    screen -d -m -S serviceMgr bash -c 'cd server/servicemgr && go build service_mgr.go && ./service_mgr'
    screen -d -m -S wsMgr bash -c 'cd server/wsmgr && go build ws_mgr.go && ./ws_mgr'
    screen -d -m -S httpMgr bash -c 'cd server/httpmgr && go build http_mgr.go && ./http_mgr'
    screen -d -m -S agtServer bash -c 'cd client/client-1.0/Go && go build agt-server.go && ./agt-server'
    screen -d -m -S atServer bash -c 'cd server/atserver && go build at-server.go && ./at-server'
}

stopme() {
    screen -X -S atServer quit
    screen -X -S agtServer quit
    screen -X -S httpMgr quit
    screen -X -S wsMgr quit
    screen -X -S serviceMgr quit
    screen -X -S serverCore quit
    #screen -wipe
}

#configureme() {
    #ln -s <absolute-path-to-dir-of-git-root>/W3C_VehicleSignalInterfaceImpl/server/Go/server-1.0/vendor/utils $GOPATH/src/utils
#}

if [ $# -ne 1 ]
then
usage $0
exit 1
fi

case "$1" in 
    startme)   startme ;;
    stopme)    stopme ;;
    #configureme)   configureme ;; 
    *) usage
       exit 1
       ;;
esac