#!/usr/bin/env bash

set -eu

usage() {
  cat <<EOF

Usage: kubectl ssh [OPTIONAL: -n <namespace>] [OPTIONAL: -u <user>] [OPTIONAL: -c <Container Name>] [ Pod Name ] -- [command]
Example: kubectl ssh -n default -u root -c prometheus prometheus-282sd0s2 -- bash

Run a command in a running container

Options:
  -h  Show usage
  -d  Enable debug mode. Print a trace of each commands
  -n  The namespace to use for this request. If not provided, defaults to current namespace.
  -u  Username or UID (format: <name|uid>[:<group|gid>]). If not provided, defaults to root.
  -c  Container name. If not provided, the first container in the pod will be chosen
EOF
  exit 0
}

to_json() {
  text="$*"
  p=""
  for i in $text; do
    [[ -n "$p" ]] && p+=", "
    p+="\"$i"\"
  done
  echo -en "$p"
}


[ $# -eq 0 ] && usage

KUBECTL="$(type -p kubectl)"
COMMAND="/bin/sh"
USERNAME="root"
CONTAINER="NONE"
NAMESPACE="NONE"

while getopts "hdp:n:u:c:" arg; do
  case $arg in
    p) # Specify pod name.
      POD=${OPTARG}
      ;;
    n) # Specify namespace
      NAMESPACE=${OPTARG}
      KUBECTL+=" --namespace=${OPTARG}"
      ;;
    u) # Specify user
      USERNAME=${OPTARG}
      ;;
    c) # Specify container
      CONTAINER=${OPTARG}
      ;;
    d) # Enable debug mode
      set -x
      ;;
    h) # Display help.
      usage
      ;;
    \?)
      usage
      ;;
  esac
done

shift $((OPTIND-1))
if [[ -z ${1+x} ]]; then
  echo "Error: You have to specify the pod name" >&2
  usage
fi
POD="$1"
shift

if [[ $# -gt 0 ]]; then
  if [[ $1 == "--" ]]; then
    shift
    COMMAND="$*"
  else
    echo "Error: Invalid option: $0" >&2
    usage
  fi
fi

echo -e "\nConnecting...\nPod: ${POD}\nNamespace: ${NAMESPACE}\nUser: ${USERNAME}\nContainer: ${CONTAINER}\nCommand: $COMMAND\n"
# $temp_container is the name of our temporary container which we use to connect behind the scenes. Will be cleaned up automatically.
temp_container="ssh-pod-${RANDOM}"

# We want to mount the docker socket on the node of the pod we're exec'ing into.
NODENAME=$( ${KUBECTL} get pod "${POD}" -o go-template='{{.spec.nodeName}}' )
NODESELECTOR='"nodeSelector": {"kubernetes.io/hostname": "'$NODENAME'"},'

# Adds toleration if the target container runs on a tainted node. Assumes no more than one taint. Change if yours have more than one or are configured differently.
TOLERATION_VALUE=$($KUBECTL get pod "${POD}" -ojsonpath='{.spec.tolerations[].value}') >/dev/null 2>&1
if [[ "$TOLERATION_VALUE" ]]; then
  TOLERATION_KEY=$($KUBECTL get pod "${POD}" -ojsonpath='{.spec.tolerations[].key}')
  TOLERATION_OPERATOR=$($KUBECTL get pod "${POD}" -ojsonpath='{.spec.tolerations[].operator}')
  TOLERATION_EFFECT=$($KUBECTL get pod "${POD}" -ojsonpath='{.spec.tolerations[].effect}')
  TOLERATIONS='"tolerations": [{"effect": "'$TOLERATION_EFFECT'","key": "'$TOLERATION_KEY'","operator": "'$TOLERATION_OPERATOR'","value": "'$TOLERATION_VALUE'"}],'
else
    TOLERATIONS=''
fi

if [[ ${CONTAINER} != "NONE" ]]; then
  DOCKER_CONTAINERID=$( eval "$KUBECTL" get pod "${POD}" -o go-template="'{{ range .status.containerStatuses }}{{ if eq .name \"${CONTAINER}\" }}{{ .containerID }}{{ end }}{{ end }}'" )
else
  DOCKER_CONTAINERID=$( $KUBECTL get pod "${POD}" -o go-template='{{ (index .status.containerStatuses 0).containerID }}' )
fi
CONTAINERID=${DOCKER_CONTAINERID#*//}

read -r -d '' OVERRIDES <<EOF || :
{
    "apiVersion": "v1",
    "metadata": {
      "annotations": {
        "sidecar.istio.io/inject" : "false"
      }
    },
    "spec": {
        "containers": [
            {
                "image": "docker",
                "name": "'$temp_container'",
                "stdin": true,
                "stdinOnce": true,
                "tty": true,
                "restartPolicy": "Never",
                "args": [
                  "exec",
                  "--privileged",
                  "-it",
                  "-u",
                  "${USERNAME}",
                  "${CONTAINERID}",
                  $(to_json "${COMMAND}")
                ],
                "volumeMounts": [
                    {
                        "mountPath": "/var/run/docker.sock",
                        "name": "docker"
                    }
                ]
            }
        ],

        $NODESELECTOR

        $TOLERATIONS

        "volumes": [
            {
                "name": "docker",
                "hostPath": {
                    "path": "/var/run/docker.sock"
                }
            }
        ]
    }
}
EOF

trap '$KUBECTL delete pod $temp_container >/dev/null 2>&1 &' 0 1 2 3 15

eval "$KUBECTL" run -it --restart=Never --image=docker --overrides="'${OVERRIDES}'" "$temp_container"
