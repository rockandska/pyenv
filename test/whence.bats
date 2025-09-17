#!/usr/bin/env bats

load test_helper

@test "finds versions where present" {
  PYENV_VERSION="2.7" create_exec_version "python" ""
  PYENV_VERSION="2.7" create_exec_version "fab" ""
  PYENV_VERSION="3.4" create_exec_version "python" ""
  PYENV_VERSION="3.4" create_exec_version "py.test" ""

  run pyenv-whence python
  assert_success
  assert_output <<OUT
2.7
3.4
OUT

  run pyenv-whence fab
  assert_success "2.7"

  run pyenv-whence py.test
  assert_success "3.4"
}
