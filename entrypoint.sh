#!/usr/bin/env bash

if [[ ! -d ${WORKSPACE}/MdePkg ]] || [[ ! -f ${WORKSPACE}/edksetup.sh ]]
then
  echo "[ERR]: not in workspace, run docker with '-v /path/to/edk2/workspace:${WORKSPACE}'!"
  exit 1
fi

args=$@
# if [[ -f ${WORKSPACE}/edksetup.sh ]]
# then
#   set --
#   source ${WORKSPACE}/edksetup.sh
#   set -- $args
# fi

if [[ $# != 0 ]]
then
  bash ${USER_HOME}/codebase.sh $@
else
  bash
fi
