#!/usr/bin/env bats

load test_helper

@test "prefix" {
  mkdir -p "${HOME}/myproject"
  cd "${HOME}/myproject"
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
  mkdir -p "${HOME}/bin"
  touch "${HOME}/bin/python"
  chmod +x "${HOME}/bin/python"
  PATH="${HOME}/libexec:$PATH" PYENV_VERSION="system" run pyenv-prefix
  assert_success "$HOME"
}

#Arch has Python at sbin as well as bin
@test "prefix for system in sbin" {
  mkdir -p "${HOME}/sbin"
  touch "${HOME}/sbin/python"
  chmod +x "${HOME}/sbin/python"
  PATH="${HOME}/sbin:$PATH" PYENV_VERSION="system" run pyenv-prefix
  assert_success "$HOME"
}

@test "prefix for system in /" {
  mkdir -p "${HOME}/libexec"
  cat >"${HOME}/libexec/pyenv-which" <<OUT
#!/bin/sh
echo /bin/python
OUT
  chmod +x "${HOME}/libexec/pyenv-which"
  PATH="${HOME}/libexec:$PATH" PYENV_VERSION="system" run pyenv-prefix
  assert_success "/"
  rm -f "${HOME}/libexec/pyenv-which"
}

@test "prefix for invalid system" {
  PATH="$(path_without python python2 python3)" run pyenv-prefix system
  assert_failure "pyenv: system version not found in PATH"
}
