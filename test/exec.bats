#!/usr/bin/env bats

load test_helper

@test "fails with invalid version" {
  bats_require_minimum_version 1.5.0
  export PYENV_VERSION="3.4"
  run -127 pyenv-exec nonexistent
  assert_failure <<EOF
pyenv: version \`3.4' is not installed (set by PYENV_VERSION environment variable)
pyenv: nonexistent: command not found
EOF
}

@test "fails with invalid version set from file" {
  bats_require_minimum_version 1.5.0
  echo 2.7 > .python-version
  run -127 pyenv-exec nonexistent
  assert_failure <<EOF
pyenv: version \`2.7' is not installed (set by $HOME/.python-version)
pyenv: nonexistent: command not found
EOF
}

@test "completes with names of executables" {
  PYENV_VERSION=3.4 create_exec_version "fab" "#!/bin/sh"
  PYENV_VERSION=3.4 create_exec_version "python" "#!/bin/sh"

  pyenv-rehash
  run pyenv-completions exec
  assert_success
  assert_output <<OUT
--help
fab
python
OUT
}

@test "carries original IFS within hooks" {
  create_hook exec hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export PYENV_VERSION=system
  IFS=$' \t\n' run pyenv-exec env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "forwards all arguments" {
  export PYENV_VERSION="3.4"
  create_exec_version "python" <<SH
#!$BASH
echo \$0
for arg; do
  # hack to avoid bash builtin echo which can't output '-e'
  printf "  %s\\n" "\$arg"
done
SH

  run pyenv-exec python -w "/path to/python script.rb" -- extra args
  assert_success
  assert_output <<OUT
${PYENV_ROOT}/versions/3.4/bin/python
  -w
  /path to/python script.rb
  --
  extra
  args
OUT
}

@test "sys.executable with system version (#98)" {
  export PATH="${PYENV_ROOT}/versions/bin:${PATH}"
  create_exec "python3" <<SH
#!$BASH
echo system
SH
  system_python="$(python3)"
  assert_equal "${system_python}" "system"

  export PYENV_VERSION="custom"
  create_exec_version "python3" "#!/bin/sh" "echo custom"

  pyenv-rehash

  custom_python="$(pyenv-exec python3)"
  assert_equal "${custom_python}" "custom"
}

@test 'PATH is not modified with system Python' {
  export PATH="${HOME}:${PATH}"
  # Create a wrapper executable that verifies PATH.
  PYENV_VERSION="custom"
  create_exec "python3" '[[ "$PATH" == "${HOME}/root/versions/custom/bin:"* ]] || { echo "unexpected:$PATH"; exit 2;}'
  unset PYENV_VERSION
  pyenv-rehash

  # Path is not modified with system Python.
  cat > "${HOME}/python3" <<SH
#!$BASH
echo \$PATH
SH
  chmod +x "${HOME}/python3"
  pyenv-rehash
  run pyenv-exec python3
  assert_success "$PATH"

  # Path is modified with custom Python.
  PYENV_VERSION=custom run pyenv-exec python3
  assert_success

  # Path is modified with custom:system Python.
  PYENV_VERSION=custom:system run pyenv-exec python3
  assert_success

  # Path is not modified with system:custom Python.
  PYENV_VERSION=system:custom run pyenv-exec python3
  assert_success "$PATH"
}
