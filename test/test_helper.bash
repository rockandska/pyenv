unset PYENV_VERSION
unset PYENV_DIR

setup() {
  if ! enable -f "${BATS_TEST_DIRNAME}"/../libexec/pyenv-realpath.dylib realpath 2>/dev/null; then
    if [ -n "$PYENV_NATIVE_EXT" ]; then
      echo "pyenv: failed to load \`realpath' builtin" >&2
      exit 1
    fi
  fi

  local bats_test_tmpdir="$(realpath "${BATS_TEST_TMPDIR}")"
  if [ -z "${bats_test_tmpdir}" ];then
    # Use readlink if running in a container instead of realpath lib
    bats_test_tmpdir="$(readlink -f "${BATS_TEST_TMPDIR}")"
  fi

  # update BATS_TEST_TMPDIR discover by realpath/readlink to avoid "//"
  export BATS_TEST_TMPDIR="${bats_test_tmpdir}"
  export HOME="${BATS_TEST_TMPDIR}"
  export PYENV_ROOT="${HOME}/.pyenv"
  export PYENV_HOOK_PATH="${PYENV_ROOT}/pyenv.d"

  # Copy src files to PYENV_ROOT
  mkdir -p "$PYENV_ROOT"
  cp -r ${BATS_TEST_DIRNAME}/../{bin,completions,libexec,man,plugins,pyenv.d,src} $PYENV_ROOT
  cp -r ${BATS_TEST_DIRNAME}/../test/libexec $PYENV_ROOT

  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
  PATH="${PYENV_ROOT}/libexec:$PATH"
  PATH="${PYENV_ROOT}/shims:$PATH"
  PATH="${PYENV_ROOT}/bin:$PATH"
  PATH="${HOME}/bin:$PATH"
  export PATH

  for xdg_var in `env 2>/dev/null | grep ^XDG_ | cut -d= -f1`; do unset "$xdg_var"; done
  unset xdg_var

  # If test specific setup exist, run it
  if [[ $(type -t _setup) == function ]];then
    _setup
  fi
}

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed "s:${HOME}:TEST_DIR:g" >&2
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status" $'\n'\
    "output: $output"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status" $'\n'\
    "output: $output"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    flunk "expected line \`$1'" $'\n'\
    "output: $output"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then
        flunk "expected to not find line \`$line'" $'\n'\
        "output: $output"
      fi
    done
  fi
}

assert() {
  if ! "$@"; then
    flunk "failed: $@"
  fi
}

# Output a modified PATH that ensures that the given executable is not present,
# but in which system utils necessary for pyenv operation are still available.
path_without() {
  local path=":${PATH}:"
  for exe; do 
    local found alt util
    for found in $(PATH="$path" type -aP "$exe"); do
      found="${found%/*}"
      if [ "$found" != "${PYENV_ROOT}/shims" ]; then
        alt="${PYENV_TEST_DIR}/$(echo "${found#/}" | tr '/' '-')"
        mkdir -p "$alt"
        for util in bash head cut readlink greadlink; do
          if [ -x "${found}/$util" ]; then
            ln -s "${found}/$util" "${alt}/$util"
          fi
        done
        path="${path/:${found}:/:${alt}:}"
      fi
    done
  done
  path="${path#:}"
  path="${path%:}"
  echo "$path"
}

create_hook() {
  mkdir -p "${PYENV_HOOK_PATH}/$1"
  touch "${PYENV_HOOK_PATH}/$1/$2"
  if [ ! -t 0 ]; then
    cat > "${PYENV_HOOK_PATH}/$1/$2"
  fi
}

create_exec_version() {
  ###
  # Create a binary in a version defined by the variable PYENV_VERSION
  # $1 binary name
  # $2-$* line of code to write to the file
  # if there is no $2, stdin is used to read content
  # Examples:
  # PYENV_VERSION=2.7 create_exec_version "test" ""
  # PYENV_VERSION=2.7 create_exec_version "test" "#!/bin/env bash" "echo test"
  # PYENV_VERSION=2.7 create_exec_version "test" <<SH
  # #!/bin/env bash
  # echo test
  # SH
  ###

  local name="${1?Missing executable name to create with 'create_exec_version'}"
  : ${PYENV_VERSION?PYENV_VERSION not set in 'create_exec_version'}
  shift 1
  local bin="${PYENV_ROOT}/versions/${PYENV_VERSION}/bin"
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else printf '%s\n' "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

create_exec() {
  ###
  # Create a binary in ${PYENV_TEST_DIR}/bin} by default
  # Destination could be overwrite with DEST variable
  # $1 binary name
  # $2-$* line of code to write to the file
  # if there is no $2, stdin is used to read content
  # Examples:
  # create_exec "test" ""
  # DEST="${BATS_TEST_TMPDIR}/bin" create_exec "test" "#!/bin/env bash" "echo test"
  # create_exec "test" <<SH
  # #!/bin/env bash
  # echo test
  # SH
  ###
  local name="${1?Missing executable name to create with 'create_exec'}"
  : ${DEST:=${HOME}/bin}
  shift 1
  local bin="${DEST}"
  unset DEST
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else printf '%s\n' "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}
