#!/usr/bin/env bats

load test_helper

copy_src_pyenvd() {
  mkdir -p "${PYENV_ROOT}"
  cp -r "${BATS_TEST_DIRNAME}/../pyenv.d" "${PYENV_ROOT}"
}

@test "pip-rehash triggered when using 'pip'" {
  export PYENV_VERSION="3.7.14"
  create_exec_version "example" ""
  create_exec_version "pip" ""
  copy_src_pyenvd
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
  copy_src_pyenvd
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
  copy_src_pyenvd
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
  copy_src_pyenvd
  run command -v example 2> /dev/null
  assert_failure
  run pyenv-exec python -m pip install example
  assert_success
  run command -v example 2> /dev/null
  assert_success
}
