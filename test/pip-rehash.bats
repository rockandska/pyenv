#!/usr/bin/env bats

load test_helper

@test "pip-rehash triggered when using 'pip'" {
  export PYENV_VERSION="3.7.14"
  create_exec_version "example" ""
  create_exec_version "pip" ""
  run command -v example 2> /dev/null
  assert_failure
  run pyenv-exec pip install example
  assert_success
  run command -v example 2> /dev/null
  assert_success
}

@test "pip-rehash triggered when using 'pip3'" {
  export PYENV_VERSION="3.7.14"
  create_exec_version "example" ""
  create_exec_version "pip3" ""
  run command -v example 2> /dev/null
  assert_failure
  run pyenv-exec pip3 install example
  assert_success
  run command -v example 2> /dev/null
  assert_success
}

@test "pip-rehash triggered when using 'pip3.x'" {
  export PYENV_VERSION="3.7.14"
  create_exec_version "example" ""
  create_exec_version "pip3.7" ""
  run command -v example 2> /dev/null
  assert_failure
  run pyenv-exec pip3.7 install example
  assert_success
  run command -v example 2> /dev/null
  assert_success
}

@test "pip-rehash triggered when using 'python -m pip install'" {
  export PYENV_VERSION="3.7.14"
  create_exec_version "example" ""
  create_exec_version "python" ""
  run command -v example 2> /dev/null
  assert_failure
  run pyenv-exec python -m pip install example
  assert_success
  run command -v example 2> /dev/null
  assert_success
}
