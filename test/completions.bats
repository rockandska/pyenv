#!/usr/bin/env bats

load test_helper

@test "command with no completion support" {
  create_exec "pyenv-hello" "#!$BASH" "echo hello"
  run pyenv-completions hello
  assert_success "--help"
}

@test "command with completion support" {
  create_exec "pyenv-hello" <<SH
#!$BASH
# Provide pyenv completions
if [[ \$1 = --complete ]]; then
  echo hello
else
  exit 1
fi
SH
  run pyenv-completions hello
  assert_success
  assert_output <<OUT
--help
hello
OUT
}

@test "forwards extra arguments" {
  create_exec "pyenv-hello" <<SH
#!$BASH
# provide pyenv completions
if [[ \$1 = --complete ]]; then
  shift 1
  for arg; do echo \$arg; done
else
  exit 1
fi
SH
  run pyenv-completions hello happy world
  assert_success
  assert_output <<OUT
--help
happy
world
OUT
}
