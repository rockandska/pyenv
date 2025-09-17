#!/usr/bin/env bats

load test_helper

@test "prefix" {
  mkdir -p "${BATS_TEST_TMPDIR}/myproject"
  cd "${BATS_TEST_TMPDIR}/myproject"
  echo "1.2.3" > .python-version
  mkdir -p "${PYENV_ROOT}/versions/1.2.3"
  run pyenv-prefix
  assert_success "${PYENV_ROOT}/versions/1.2.3"
}

@test "prefix for invalid version" {
  PYENV_VERSION="1.2.3" run pyenv-prefix
  assert_failure "pyenv: version \`1.2.3' not installed"
}

@test "prefix for system" {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  touch "${BATS_TEST_TMPDIR}/bin/python"
  chmod +x "${BATS_TEST_TMPDIR}/bin/python"
  PATH="${BATS_TEST_TMPDIR}/libexec:$PATH" PYENV_VERSION="system" run pyenv-prefix
  assert_success "$BATS_TEST_TMPDIR"
}

#Arch has Python at sbin as well as bin
@test "prefix for system in sbin" {
  mkdir -p "${BATS_TEST_TMPDIR}/sbin"
  touch "${BATS_TEST_TMPDIR}/sbin/python"
  chmod +x "${BATS_TEST_TMPDIR}/sbin/python"
  PATH="${BATS_TEST_TMPDIR}/sbin:$PATH" PYENV_VERSION="system" run pyenv-prefix
  assert_success "$BATS_TEST_TMPDIR"
}

@test "prefix for system in /" {
  mkdir -p "${BATS_TEST_TMPDIR}/libexec"
  cat >"${BATS_TEST_TMPDIR}/libexec/pyenv-which" <<OUT
#!/bin/sh
echo /bin/python
OUT
  chmod +x "${BATS_TEST_TMPDIR}/libexec/pyenv-which"
  PATH="${BATS_TEST_TMPDIR}/libexec:$PATH" PYENV_VERSION="system" run pyenv-prefix
  assert_success "/"
  rm -f "${BATS_TEST_TMPDIR}/libexec/pyenv-which"
}

@test "prefix for invalid system" {
  PATH="$(path_without python python2 python3)" run pyenv-prefix system
  assert_failure "pyenv: system version not found in PATH"
}
