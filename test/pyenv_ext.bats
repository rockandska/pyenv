#!/usr/bin/env bats

load test_helper

@test "prefixes" {
  mkdir -p "${HOME}/bin"
  touch "${HOME}/bin/python"
  chmod +x "${HOME}/bin/python"
  mkdir -p "${PYENV_ROOT}/versions/2.7.10"
  PYENV_VERSION="system:2.7.10" run pyenv-prefix
  assert_success "${HOME}:${PYENV_ROOT}/versions/2.7.10"
  PYENV_VERSION="2.7.10:system" run pyenv-prefix
  assert_success "${PYENV_ROOT}/versions/2.7.10:${HOME}"
}
