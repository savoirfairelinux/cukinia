#!/usr/bin/env bats

load '/usr/lib/bats/bats-support/load'
load '/usr/lib/bats/bats-assert/load'
load './bats-mock/stub.bash'

setup() {
    # Mocking commands to pass in CI
    BATS_MOCK_BINDIR="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$BATS_MOCK_BINDIR"
    export PATH="$BATS_MOCK_BINDIR:$PATH"

    # Mock cukinia_cmdline
    cat <<'EOF' >"$BATS_MOCK_BINDIR/grep"
#!/bin/bash
if [[ "$1 $2" =~ (^|\ )quiet(\ |$) ]]; then
    exit 0
else
    /bin/grep "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/grep"

    # Mock cukinia_http_request
    cat <<'EOF' >"$BATS_MOCK_BINDIR/wget"
#!/bin/sh
if [ "$1 $2 $3 $4" = "-q -O /dev/null http://localhost:631/" ]; then
    exit 0
else
    /usr/bin/wget "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/wget"

    # Mock cukinia_kmod
    cat <<'EOF' >"$BATS_MOCK_BINDIR/grep"
#!/bin/bash
if [[ "$1 $2" =~ ^inet_diag\ /proc/modules ]]; then
    exit 0
else
    /bin/grep "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/grep"

    # Mock cukinia_listen4
    cat <<'EOF' >"$BATS_MOCK_BINDIR/netstat"
#!/bin/sh
if [ "$1 $2 $3" = "-lnt tcp 631" ]; then
    exit 0
elif [ "$1 $2 $3" = "-lnu udp 5353" ]; then
    exit 0
elif [ "$1 $2 $3" = "-lntu any 67" ];then
    exit 0
else
    /bin/netstat "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/netstat"

    # Mock cukinia_netif_has_ip
    cat <<'EOF' >"$BATS_MOCK_BINDIR/ip"
#!/bin/sh
if [ "$1 $2 $3 $4 $5 $6 $7" = "-o -4 addr show dev $gw_if dynamic" ]; then
    exit 0
else
    /sbin/ip "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/ip"

    # Mock cukinia_wifi_is_connected
    cat <<'EOF' >"$BATS_MOCK_BINDIR/iw"
#!/bin/sh
if [ "$1 $2 $3" = "dev dummy0 link" ]; then
    echo "Connected to aa:bb:cc:dd:ee:ff (on dummy0)"
    exit 0
else
    /usr/sbin/iw "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/iw"

    # Mock cukinia_systemd_unit
    cat <<'EOF' >"$BATS_MOCK_BINDIR/systemctl"
#!/bin/sh
if [ "$1 $2" = "is-active atd.service" ]; then
    exit 0
else
    /bin/systemctl "$@"
fi
EOF
    chmod +x "$BATS_MOCK_BINDIR/systemctl"
}

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

@test "Run cukinia testcases-failure" {
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

@test "Cukinia Junit XML validation" {
    run ./cukinia tests/xml/lint.conf
    assert_success
    run ./cukinia tests/xml/xml.conf
    assert_success
}
