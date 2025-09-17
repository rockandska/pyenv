#!/usr/bin/env bats

load test_helper

create_alias() {
  mkdir -p "${PYENV_ROOT}/versions"
  ln -s "$2" "${PYENV_ROOT}/versions/$1"
}

_setup() {
  mkdir -p "$PYENV_TEST_DIR"
  cd "$PYENV_TEST_DIR"
}

@test "no versions installed" {
  create_exec python ""
  assert [ ! -d "${PYENV_ROOT}/versions" ]
  run pyenv-versions
  assert_success "* system (set by ${PYENV_ROOT}/version)"
}

@test "not even system python available" {
  PATH="$(path_without python python2 python3)" run pyenv-versions
  assert_failure
  assert_output "Warning: no Python detected on the system"
}

@test "bare output no versions installed" {
  assert [ ! -d "${PYENV_ROOT}/versions" ]
  run pyenv-versions --bare
  assert_success ""
}

@test "single version installed" {
  create_exec python ""
  PYENV_VERSION=3.3 create_exec_version "python" ""
  run pyenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${PYENV_ROOT}/version)
  3.3
OUT
}

@test "single version bare" {
  PYENV_VERSION=3.3 create_exec_version "python" ""
  run pyenv-versions --bare
  assert_success "3.3"
}

@test "multiple versions and envs" {
  create_exec python ""
  PYENV_VERSION="2.7.6" create_exec_version "python" ""
  PYENV_VERSION="3.4.0" create_exec_version "python" ""
  PYENV_VERSION="3.4.0/envs/foo" create_exec_version "python" ""
  PYENV_VERSION="3.4.0/envs/bar" create_exec_version "python" ""
  PYENV_VERSION="3.5.2" create_exec_version "python" ""
  run pyenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${PYENV_ROOT}/version)
  2.7.6
  3.4.0
  3.4.0/envs/bar
  3.4.0/envs/foo
  3.5.2
OUT
}

@test "skips envs with --skip-envs" {
  PYENV_VERSION="3.3.3" create_exec_version "python" ""
  PYENV_VERSION="3.4.0" create_exec_version "python" ""
  PYENV_VERSION="3.4.0/envs/foo" create_exec_version "python" ""
  PYENV_VERSION="3.4.0/envs/bar" create_exec_version "python" ""
  PYENV_VERSION="3.5.0" create_exec_version "python" ""

  run pyenv-versions --skip-envs
    assert_success <<OUT
* system (set by ${PYENV_ROOT}/version)
  3.3.3
  3.4.0
  3.5.0
OUT
}

@test "indicates current version" {
  create_exec python ""
  PYENV_VERSION="3.3.3" create_exec_version "python" ""
  PYENV_VERSION="3.4.0" create_exec_version "python" ""
  PYENV_VERSION=3.3.3 run pyenv-versions
  assert_success
  assert_output <<OUT
  system
* 3.3.3 (set by PYENV_VERSION environment variable)
  3.4.0
OUT
}

@test "bare doesn't indicate current version" {
  PYENV_VERSION="3.3.3" create_exec_version "python" ""
  PYENV_VERSION="3.4.0" create_exec_version "python" ""
  PYENV_VERSION=3.3.3 run pyenv-versions --bare
  assert_success
  assert_output <<OUT
3.3.3
3.4.0
OUT
}

@test "globally selected version" {
  create_exec python ""
  PYENV_VERSION="3.3.3" create_exec_version "python" ""
  PYENV_VERSION="3.4.0" create_exec_version "python" ""
  cat > "${PYENV_ROOT}/version" <<<"3.3.3"
  run pyenv-versions
  assert_success
  assert_output <<OUT
  system
* 3.3.3 (set by ${PYENV_ROOT}/version)
  3.4.0
OUT
}

@test "per-project version" {
  create_exec python ""
  PYENV_VERSION="3.3.3" create_exec_version "python" ""
  PYENV_VERSION="3.4.0" create_exec_version "python" ""
  cat > ".python-version" <<<"3.3.3"
  run pyenv-versions
  assert_success
  assert_output <<OUT
  system
* 3.3.3 (set by ${PYENV_TEST_DIR}/.python-version)
  3.4.0
OUT
}

@test "ignores non-directories under versions" {
  PYENV_VERSION="3.3" create_exec_version "python" ""
  touch "${PYENV_ROOT}/versions/hello"

  run pyenv-versions --bare
  assert_success "3.3"
}

@test "lists symlinks under versions" {
  PYENV_VERSION="2.7.8" create_exec_version "python" ""
  create_alias "2.7" "2.7.8"

  run pyenv-versions --bare
  assert_success
  assert_output <<OUT
2.7
2.7.8
OUT
}

@test "doesn't list symlink aliases when --skip-aliases" {
  PYENV_VERSION="1.8.7" create_exec_version "python" ""
  create_alias "1.8" "1.8.7"
  mkdir moo
  create_alias "1.9" "${PWD}/moo"

  run pyenv-versions --bare --skip-aliases
  assert_success

  assert_output <<OUT
1.8.7
1.9
OUT
}

@test "lists dot directories under versions" {
  PYENV_VERSION=".venv" create_exec_version "python" ""

  run pyenv-versions --bare
  assert_success ".venv"
}

@test "sort supports version sorting" {
  PYENV_VERSION="1.9.0" create_exec_version "python" ""
  PYENV_VERSION="1.53.0" create_exec_version "python" ""
  PYENV_VERSION="1.218.0" create_exec_version "python" ""
  create_exec sort <<SH
#!$BASH
cat >/dev/null
if [ "\$1" == "--version-sort" ]; then
  echo "${PYENV_ROOT}/versions/1.9.0"
  echo "${PYENV_ROOT}/versions/1.53.0"
  echo "${PYENV_ROOT}/versions/1.218.0"
else exit 1
fi
SH

  run pyenv-versions --bare
  assert_success
  assert_output <<OUT
1.9.0
1.53.0
1.218.0
OUT
}

@test "sort doesn't support version sorting" {
  PYENV_VERSION="1.9.0" create_exec_version "python" ""
  PYENV_VERSION="1.53.0" create_exec_version "python" ""
  PYENV_VERSION="1.218.0" create_exec_version "python" ""
  create_exec sort <<SH
#!$BASH
exit 1
SH

  run pyenv-versions --bare
  assert_success
  assert_output <<OUT
1.218.0
1.53.0
1.9.0
OUT
}

@test "non-bare output shows symlink contents" {
  create_exec python ""
  PYENV_VERSION="1.9.0" create_exec_version "python" ""
  create_alias "link" "1.9.0"

  run pyenv-versions
  assert_success
  assert_output <<OUT
* system (set by ${PYENV_ROOT}/version)
  1.9.0
  link --> 1.9.0
OUT
}
