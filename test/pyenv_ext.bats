#!/usr/bin/env bats

load test_helper

@test "prefixes" {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  touch "${BATS_TEST_TMPDIR}/bin/python"
  chmod +x "${BATS_TEST_TMPDIR}/bin/python"
  mkdir -p "${PYENV_ROOT}/versions/2.7.10"
  PYENV_VERSION="system:2.7.10" run pyenv-prefix
  assert_success "${BATS_TEST_TMPDIR}:${PYENV_ROOT}/versions/2.7.10"
  PYENV_VERSION="2.7.10:system" run pyenv-prefix
  assert_success "${PYENV_ROOT}/versions/2.7.10:${BATS_TEST_TMPDIR}"
}
