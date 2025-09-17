#!/usr/bin/env bats

load test_helper

@test "empty rehash" {
  assert [ ! -d "${PYENV_ROOT}/shims" ]
  run pyenv-rehash
  assert_success ""
  assert [ -d "${PYENV_ROOT}/shims" ]
  rmdir "${PYENV_ROOT}/shims"
}

@test "non-writable shims directory" {
  mkdir -p "${PYENV_ROOT}/shims"
  chmod -w "${PYENV_ROOT}/shims"
  run pyenv-rehash
  assert_failure "pyenv: cannot rehash: ${PYENV_ROOT}/shims isn't writable"
}

@test "rehash in progress" {
  export PYENV_REHASH_TIMEOUT=1
  mkdir -p "${PYENV_ROOT}/shims"
  touch "${PYENV_ROOT}/shims/.pyenv-shim"
  run pyenv-rehash
  assert_failure "pyenv: cannot rehash: ${PYENV_ROOT}/shims/.pyenv-shim exists"
}

@test "wait until lock acquisition" {
  export PYENV_REHASH_TIMEOUT=5
  mkdir -p "${PYENV_ROOT}/shims"
  touch "${PYENV_ROOT}/shims/.pyenv-shim"
  bash -c "sleep 1 && rm -f ${PYENV_ROOT}/shims/.pyenv-shim" &
  run pyenv-rehash
  assert_success
}

@test "creates shims" {
  PYENV_VERSION=2.7 create_exec_version "python" ""
  PYENV_VERSION=2.7 create_exec_version "fab" ""
  PYENV_VERSION=3.4 create_exec_version "python" ""
  PYENV_VERSION=3.4 create_exec_version "py.test" ""

  assert [ ! -e "${PYENV_ROOT}/shims/fab" ]
  assert [ ! -e "${PYENV_ROOT}/shims/python" ]
  assert [ ! -e "${PYENV_ROOT}/shims/py.test" ]

  run pyenv-rehash
  assert_success ""

  run ls "${PYENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
fab
py.test
python
OUT
}

@test "removes stale shims" {
  mkdir -p "${PYENV_ROOT}/shims"
  touch "${PYENV_ROOT}/shims/oldshim1"
  chmod +x "${PYENV_ROOT}/shims/oldshim1"

  PYENV_VERSION=3.4 create_exec_version "fab" ""
  PYENV_VERSION=3.4 create_exec_version "python" ""

  run pyenv-rehash
  assert_success ""

  assert [ ! -e "${PYENV_ROOT}/shims/oldshim1" ]
}

@test "binary install locations containing spaces" {
  PYENV_VERSION="dirname1 p247" create_exec_version "python" ""
  PYENV_VERSION="dirname2 preview1" create_exec_version "py.test" ""

  assert [ ! -e "${PYENV_ROOT}/shims/python" ]
  assert [ ! -e "${PYENV_ROOT}/shims/py.test" ]

  run pyenv-rehash
  assert_success ""

  run ls "${PYENV_ROOT}/shims"
  assert_success
  assert_output <<OUT
py.test
python
OUT
}

@test "carries original IFS within hooks" {
  create_hook rehash hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' run pyenv-rehash
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "sh-rehash in bash" {
  PYENV_VERSION=3.4 create_exec_version "python" ""
  PYENV_SHELL=bash run pyenv-sh-rehash
  assert_success "hash -r 2>/dev/null || true"
  assert [ -x "${PYENV_ROOT}/shims/python" ]
}

@test "sh-rehash in fish" {
  PYENV_VERSION=3.4 create_exec_version "python" ""
  PYENV_SHELL=fish run pyenv-sh-rehash
  assert_success ""
  assert [ -x "${PYENV_ROOT}/shims/python" ]
}
