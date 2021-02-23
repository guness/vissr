# (C) 2021 Mitsubishi Electric Automotive Europe B.V.
#
# All files and artifacts in the repository at https://github.com/MEAE-GOT/W3C_VehicleSignalInterfaceImpl
# are licensed under the provisions of the license provided by the LICENSE file in this repository.

ARG GO_VERSION=1.13
ARG VSSTREE_NAME="vss_vissv2.binary"

#----------------------Builder-----------------------
FROM golang:${GO_VERSION}-alpine AS builder
ARG VSSTREE_NAME
WORKDIR /build
#install gcc and std lib
RUN apk add --no-cache gcc musl-dev
#add bin folder to store the compiled files
RUN mkdir bin
#add the content of the server dir
COPY server/ .
#add the utils dir
COPY utils ./utils
#add the go module files
COPY go.mod go.sum ./
#remove these since these arent currently buildable and shouldnt be included
RUN rm -rf test
RUN rm -rf signal_broker
RUN rm hist_ctrl_client.go
#clean up unused dependencies
RUN go mod tidy
#compile all projects and place the executables in the bin folder
RUN go build -v -o ./bin ./...
#----------------------DONE with builder-----------------------

#----------------------server_core-----------------------
FROM alpine:latest AS server_core
ARG VSSTREE_NAME
WORKDIR /app
COPY --from=builder /build/bin/server_core .
COPY --from=builder /build/server_core/${VSSTREE_NAME} .
RUN /app/server_core -p
#----------------------DONE with server_core-----------------------

#----------------------at_server-----------------------
FROM alpine:latest AS at_server
ARG VSSTREE_NAME
WORKDIR /app
COPY --from=builder /build/bin/at_server .
COPY --from=builder /build/at_server/${VSSTREE_NAME} .
#copy *.json (purpose/scope) maybe these should be moved to
#config folder and mounted so that they can be changed without
#rebuilding the container
COPY --from=builder /build/at_server/purposelist.json .
COPY --from=builder /build/at_server/scopelist.json .
#----------------------DONE with at_server-----------------------

#----------------------agt_server-----------------------
FROM alpine:latest AS agt_server
WORKDIR /app
COPY --from=builder /build/bin/agt_server .
#----------------------DONE with agt_server-----------------------

#----------------------service_mgr-----------------------
FROM alpine:latest AS service_mgr
WORKDIR /app
RUN mkdir -p /tmp/vissv2/
COPY --from=builder /build/bin/service_mgr .
#this copy can be problematic since it generated by server_core at runtime
#20210219 fix added in service_mgr to handle the missing file more gracefully :)
COPY --from=server_core /vsspathlist.json .
#----------------------DONE with service_mgr-----------------------

#----------------------http_mgr-----------------------
FROM alpine:latest AS http_mgr
WORKDIR /app
COPY --from=builder /build/bin/http_mgr .
#----------------------DONE with http_mgr-----------------------

#----------------------ws_mgr-----------------------
FROM alpine:latest AS ws_mgr
WORKDIR /app
COPY --from=builder /build/bin/ws_mgr .
#----------------------DONE with ws_mgr-----------------------

#----------------------mqtt_mgr-----------------------
FROM alpine:latest AS mqtt_mgr
WORKDIR /app
COPY --from=builder /build/bin/mqtt_mgr .
#----------------------DONE with mqtt_mgr-----------------------