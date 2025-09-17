#!/usr/bin/env bats

load test_helper

@test "prints usage help given no argument" {
  run pyenv-hooks
  assert_failure "Usage: pyenv hooks <command>"
}

@test "prints list of hooks" {
  path1="${PYENV_ROOT}/pyenv.d"
  path2="${HOME}/etc/pyenv_hooks"
  PYENV_HOOK_PATH="$path1"
  create_hook exec "invalid.sh"
  create_hook which "boom.bash"
  PYENV_HOOK_PATH="$path2"
  create_hook exec "bueno.bash"

  PYENV_HOOK_PATH="$path1:$path2" run pyenv-hooks exec
  assert_success
  assert_output <<OUT
${PYENV_ROOT}/pyenv.d/exec/pip-rehash.bash
${HOME}/etc/pyenv_hooks/exec/bueno.bash
OUT
}

@test "supports hook paths with spaces" {
  path1="${HOME}/my hooks/pyenv.d"
  path2="${HOME}/etc/pyenv hooks"
  PYENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  PYENV_HOOK_PATH="$path2"
  create_hook exec "ahoy.bash"

  PYENV_HOOK_PATH="$path1:$path2" run pyenv-hooks exec
  assert_success
  assert_output <<OUT
${HOME}/my hooks/pyenv.d/exec/hello.bash
${HOME}/etc/pyenv hooks/exec/ahoy.bash
OUT
}

@test "resolves relative paths" {
  PYENV_HOOK_PATH="${HOME}/pyenv.d" create_hook exec "hello.bash"
  PYENV_HOOK_PATH="${PYENV_ROOT}/../pyenv.d" run pyenv-hooks exec
  assert_success "${HOME}/pyenv.d/exec/hello.bash"
}

@test "resolves symlinks" {
  path="${HOME}/pyenv.d"
  mkdir -p "${path}/exec"
  mkdir -p "$HOME"
  touch "${HOME}/hola.bash"
  ln -s "${PYENV_ROOT}/../hola.bash" "${path}/exec/hello.bash"
  touch "${path}/exec/bright.sh"
  ln -s "bright.sh" "${path}/exec/world.bash"

  PYENV_HOOK_PATH="$path" run pyenv-hooks exec
  assert_success
  assert_output <<OUT
${HOME}/hola.bash
${HOME}/pyenv.d/exec/bright.sh
OUT
}
