#!/usr/bin/env bats

load '/usr/lib/bats/bats-support/load'
load '/usr/lib/bats/bats-assert/load'

@test "Run cukinia testcases" {
    run ./cukinia tests/testcases.conf
    assert_success

    assert_line --partial '----> cukinia_cmd <----'
    assert_line --regexp '.*SKIP.*  Should PASS on arm64 only or skip*'
    assert_line --regexp '.*SKIP.*  Should SKIP on PC only*'

    assert_line --regexp '.*etry.*"Should pass and retry 2 times" in 0s.*'
    assert_line --regexp '.*etry.*"Should pass and retry 2 times" in 0s.*'
    assert_line --regexp '.*PASS.*  Should pass and retry 2 times.*'
    assert_line --regexp '.*SKIP.*  Should skip*'
    assert_line --regexp '.*etry.*"Should pass and retry 1 time" in 2s.*'
    assert_line --regexp '.*PASS.*  Should pass and retry 1 time.*'

    assert_line --regexp '^ran .* tests.*$'
}

@test "Run cukinia testcases-failure {
    run sh ./cukinia tests/testcases-failure.conf

    assert_line --regexp '.*FAIL.*  Checking if gpiochip0 pins are well configured via libgpiod.*'
    assert_line --regexp '.*FAIL.*  Checking if gpiochip0 pins are well configured via sysfs.*'

    assert_line --regexp '.*FAIL.*  Should fail and retry 3 times.*'
    assert_line --regexp '.*FAIL.*  Should fail .no retries.*'

    assert_line --regexp '.*FAIL.*  Running "false" is successful.*'
    assert_line --regexp '.*FAIL.*  Running "true" is NOT successful*'
    assert_line --regexp '.*FAIL.*  Running "test 0 -eq 1" returns success.*'
    assert_line --regexp '.*FAIL.*  Checking process "nosuchprocess" running as any user.*'
    assert_line --regexp '.*FAIL.*  Checking python package "nosuchpackage" is available.*'
    assert_line --regexp '.*FAIL.*  Checking link "/dev/zero" does point to "/dev/null".*'
    assert_line --regexp '.*FAIL.*  Checking if systemd unit "nosuchunit.service" is active.*'
    assert_line --regexp '.*FAIL.*  SWR_003 -- Running "false" is successful.*'
}
