#!/bin/bash
#
#  Copyright ©2020 efikarl, https://efikarl.com.
#
#  This program is just made available under the terms and conditions of the
#  MIT license: https://efikarl.com/mit-license.html.
#
#  THE PROGRAM IS DISTRIBUTED UNDER THE MIT LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
shopt -s extglob
shopt -s dotglob

THIS_SCRIPT=$(readlink -f ${BASH_SOURCE:-$0})
SCRIPT_PATH=$( dirname ${THIS_SCRIPT})
SCRIPT_NAME=$(basename ${THIS_SCRIPT})

EDKII_PATH=${BASESPACE}
LIANO_PATH=${WORKSPACE}
echo EDKII_PATH:$EDKII_PATH
echo LIANO_PATH:$LIANO_PATH

help_info()
{
  echo '  ------------------------------------------------------------------------  '
  echo '  usage: clean workspace of raw codebase                                    '
  echo '    codebase.sh [-s sel] [-t tag]                                           '
  echo '  option:                                                                   '
  echo '    -s sel            --select step to run, run all steps if not set.       '
  echo '    -t tag            --set tag to update                                   '
  echo '  ------------------------------------------------------------------------  '
}

param_parse()
{
  while getopts "s:t:" arg
  do
    case $arg in
    s)
      export sel=$OPTARG
      ;;
    t)
      export tag=$OPTARG
      ;;
    ?)
      help_info && return 1
      ;;
    esac
  done

  return 0
}

setup_edk_ii_repo()
{
  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: ...."
  git clone ${GITHUB_MIRROR}/tianocore/edk2.git ${EDKII_PATH}
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: git clone!"
    return 1
  fi

  cd ${EDKII_PATH}
  if [[ ! -d MdePkg ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: not in workspace!"
    return 1
  fi

  if [[ -z $tag ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: tag is not set!"
    return 1
  fi

  git checkout      $tag                          > /dev/null 2>&1
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: git checkout!"
    return 1
  fi

  (git reset --hard $tag && git clean -xfd)       > /dev/null 2>&1
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: git reset and clean!"
    return 1
  fi

  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: done"
  return 0
}

clean_ws_for_ovmf()
{
  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: ...."

  cd ${EDKII_PATH}
  if [[ ! -d MdePkg ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: not in workspace!"
    return 1
  fi
  # remove all packages that is not of ovmf
  for f in $(ls -a)
  do
    cat OvmfPkg/OvmfPkgIa32X64.dsc | grep $f > /dev/null || rm -rf $f
  done
  # checkout back ovmf indirect depex packages
  git checkout HEAD -- BaseTools CryptoPkg EmbeddedPkg FatPkg MdeModulePkg MdePkg NetworkPkg OvmfPkg PcAtChipsetPkg SecurityPkg ShellPkg SourceLevelDebugPkg UefiCpuPkg edksetup.sh License-History.txt License.txt Maintainers.txt

  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: done"
  return 0
}

add_git_submodule()
{
  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: ...."

  cd ${EDKII_PATH}
  if [[ ! -d MdePkg ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: not in workspace!"
    return 1
  fi

  if [[ -z $tag ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: tag is not set!"
    return 1
  fi

  submod_url_rls="tianocore/edk2/releases/download"
  submod_url_tag=$tag

  declare -a submod_src
  submod_src[1]=submodule-BaseTools-Source-C-BrotliCompress-brotli.zip
  submod_src[2]=submodule-CryptoPkg-Library-OpensslLib-openssl.zip
  submod_src[3]=submodule-MdeModulePkg-Library-BrotliCustomDecompressLib-brotli.zip
  submod_src[4]=submodule-MdeModulePkg-Universal-RegularExpressionDxe-oniguruma.zip

  for i in {1..4}
  do
    if [[ -n ${submod_src[$i]} ]]
    then
      echo url:${GITHUB_MIRROR}/${submod_url_rls}/${submod_url_tag}/${submod_src[$i]}
      curl -LO ${GITHUB_MIRROR}/${submod_url_rls}/${submod_url_tag}/${submod_src[$i]}
      if [[ $? != 0 ]]
      then
        echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: submode_src[$i]!"
        rm -f ${submod_src[$i]}
        return 1
      fi
      unzip -u ${submod_src[$i]} > /dev/null && rm -f ${submod_src[$i]}
    fi
  done

  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: done"
  return 0
}

codebase_to_linao()
{
  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: ...."

  cd ${LIANO_PATH}
  if [[ ! -d MdePkg ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: not in workspace!"
    return 1
  fi

  git checkout      codebase                      > /dev/null 2>&1
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: git checkout!"
    return 1
  fi

  (git reset --hard codebase && git clean -xfd)   > /dev/null 2>&1
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: git reset and clean!"
    return 1
  fi

  #+ shopt -u dotglob && shopt -u extglob
  rm -rf !(.|..|.git)
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: rm -rf !(.git)"
    return 1
  fi
  cp -rf ${EDKII_PATH}/!(.|..|.git) ${LIANO_PATH}
  if [[ $? != 0 ]]
  then
    echo "ERR:${SCRIPT_NAME}:${FUNCNAME[0]}: cp -rf !(.git)"
    return 1
  fi
  #- shopt -u dotglob && shopt -u extglob

  (git add . && git commit -s -m "codebase => $tag") > /dev/null 2>&1

  echo "${SCRIPT_NAME}:${FUNCNAME[0]}: done"
  return 0
}

param_parse $@
[[ $? != 0 ]] && exit 0

case $sel in
1)
  setup_edk_ii_repo
  [[ $? != 0 ]] && exit 1
  ;;
2)
  clean_ws_for_ovmf
  [[ $? != 0 ]] && exit 2
  ;;
3)
  add_git_submodule
  [[ $? != 0 ]] && exit 3
  ;;
4)
  codebase_to_linao
  [[ $? != 0 ]] && exit 4
  ;;
*)
  setup_edk_ii_repo
  [[ $? != 0 ]] && exit 1
  clean_ws_for_ovmf
  [[ $? != 0 ]] && exit 2
  add_git_submodule
  [[ $? != 0 ]] && exit 3
  codebase_to_linao
  [[ $? != 0 ]] && exit 4
  ;;
esac

shopt -u dotglob
shopt -u extglob
exit 0
