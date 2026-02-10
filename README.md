![cukinia logo](./doc/cukinia_logo.png?raw=true)

> Simple, on-target validation framework for embedded Linux systems

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/savoirfairelinux/cukinia)](https://github.com/savoirfairelinux/cukinia/releases)
[![Cukinia Test Suite](https://github.com/savoirfairelinux/cukinia/actions/workflows/run-cukinia.yml/badge.svg)](https://github.com/savoirfairelinux/cukinia/actions/workflows/run-cukinia.yml)

# Cukinia Test Framework

Cukinia is designed to help embedded Linux firmware developers run simple
system-level validation tests on their systems.

It integrates well with embedded system generation frameworks such as Yocto and
Buildroot, and can be run manually, or by your favourite CI framework.

## Project objectives

Cukinia works if it offers the following value:

* It is very simple to use
* It requires no dependencies other than a POSIX shell (e.g. Busybox)
* It integrates easily with CI/CD pipelines
* It helps developers creating better systems

## Usage

```
USAGE:
	cukinia [options] [config file]

OPTIONS:
	-h, --help	display this message
	-v, --version	display the version string
	-o <file>	output results to <file>
	-f <format>	set output format to <format>, currently supported:
       			csv junitxml
	--no-header	do not print headers in concerned output formats
	--trace         trace execution (for debugging)
```

By default, Cukinia uses `/etc/cukinia.conf`.

## Screenshot

A sample screenshot when running Cukinia in interactive mode:

![Screenshot](doc/screenshot.png)

---

# Cukinia Test Statements

Cukinia provides a set of simple statements for validating runtime aspects of a
Linux system:

## 👤 User & Group Management

Verify the presence and configuration of system users and groups.

- `cukinia_user <name>` → validate that a user exists
- `cukinia_group <name>` → validate that a group exists
- `cukinia_user_memberof <user> <group>[ ...]` → validate that a user is member of one or more groups

**Example:**
```sh
cukinia_user appuser
cukinia_group dialout
cukinia_user_memberof appuser dialout video
```

---

## 🔧 Processes & Threads

- `cukinia_kthread <name>` → validate that a kernel thread is running
- `cukinia_process <name> [user]` → validate that a process is running (optional owner)
- `cukinia_process_with_args "<args>" [user]` → validate that a process with specific arguments is running (optional owner)

**Examples**

```sh
cukinia_kthread kworker/0:1
cukinia_process sshd
cukinia_process_with_args "gpsd --nodaemon" appuser
```

---

## 🐧 Kernel & System Configuration

- `cukinia_cmdline <param>[=<value>]` → validate that kernel cmdline contains a parameter (optional value)
- `cukinia_kconf <symbol> <y|m|n>` → validate that a kernel config symbol has a given tristate value
- `cukinia_kmod <module>` → validate that a kernel module is loaded
- `cukinia_knoerror <priority>` → validate that kernel boot has no important errors at or above the given log priority
  - **Note:** This test requires `dmesg --level` support, which is not available in BusyBox by default. To use this test with BusyBox, enable `CONFIG_FEATURE_DMESG_LEVEL` in your BusyBox configuration. Alternatively, use `cukinia_cmd` with custom grep patterns for more control over error detection.
- `cukinia_kversion <maj.min>` → validate kernel version (checks major.minor, e.g. 5.14)
- `cukinia_sysctl <key> <value>` → validate that a kernel sysctl parameter is set to value

**Examples**

```sh
cukinia_cmdline console=ttyS0
cukinia_kconf CONFIG_IPV6 y
cukinia_kmod i2c_dev
cukinia_kversion 6.6
cukinia_sysctl net.ipv4.ip_forward 0
```

---

## 🧩 Generic commands and test(1) expressions

The `cukinia_test` statement wraps the shell `test` command, allowing for
generic tests, while `cukinia_cmd` allows for running arbitrary commands.

- `cukinia_test <test(1) expression>` → validate a generic `test` expression
- `cukinia_cmd <command...>` → validate that an arbitrary command returns success

**Examples**

```sh
cukinia_test -f /etc/os-release

result_string=$(some_command)
as "The remote sensor was detected" \
    cukinia_test "$result_string" = "Detected"

as "The root user's password field is not empty" \
    not cukinia_cmd "grep -q ^root:: /etc/passwd"
```

---

## 💾 Filesystems & Paths

- `cukinia_mount <device> <target> [fstype] [options]` → validate the presence of a mount
- `cukinia_symlink <path> <expected_target>` → validate the target of a symlink

**Examples**
```sh
cukinia_mount sysfs /sys
cukinia_mount /dev/sda5 /mnt/maps ext4 ro
cukinia_symlink /etc/alternatives/editor /usr/bin/vim
```

---

## 🌐 Networking & Connectivity

- `cukinia_dns_resolve <hostname>` → validate that a hostname can be resolved
- `cukinia_http_request <url>` → validate that an HTTP(S) request returns HTTP 200
- `cukinia_listen4 <tcp|udp> <port>` → validate that a TCP/UDP v4 port is open locally
- `cukinia_netif_has_ip <ifname> [-4|-6] [flags]` → validate that an interface has IP configuration (examples below)
- `cukinia_netif_is_up <ifname>` → validate interface state is UP

**Examples**

```sh
cukinia_dns_resolve example.org
cukinia_http_request http://localhost:8080/health
cukinia_listen4 tcp 22
cukinia_netif_has_ip eth0 -4 dynamic
cukinia_netif_has_ip eth0 -6 "scope global"
cukinia_netif_is_up eth2
```

---

## 🔌 Devices & Buses

- `cukinia_gpio_libgpiod -i <in_pins> -l <out_low> -h <out_high> -g <gpiochip>` → validate GPIO via libgpiod
- `cukinia_gpio_sysfs -i <in_pins> -l <out_low> -h <out_high> -g <gpiochip>` → validate GPIO via legacy sysfs
- `cukinia_i2c <bus> [device_address] [driver_name]` → check I²C bus or (optional) device and (optionally) that it uses the indicated driver

**Examples**

```sh
cukinia_gpio_libgpiod -i "0 3 4" -l "10" -h "2 50" -g gpiochip1
cukinia_gpio_sysfs -i "20 34" -h "3 99 55"

as "Remote MCU is visible on I2C2 bus address 3c" \
    cukinia_i2c 1 0x3c
```

---

## 🟦 systemd units

- `cukinia_systemd_unit <unit>` → validate that a systemd unit is active
- `cukinia_systemd_failed` → fail if any systemd unit is in failed state

**Examples**

```sh
cukinia_systemd_unit sshd.service
cukinia_systemd_failed
```

---

## 🐍 Python

- `cukinia_python_pkg <package>` → validate that a Python package is installed

**Examples**

```sh
cukinia_python_pkg requests
```

---

## 🎛️ Modifiers (Prefixes)

These **prefix** any test statement and may be combined:

- `as "<description>"` → change a test's textual description
- `not` → invert the test result (appends `[!]` in the default description)
- `test_id "<id>"` → set a test id for outputs (useful for mapping your system requirements)
- `verbose` → preserve test stdout/stderr in the console output

**Examples**

```sh
as "Checking embedded webapp is up (with connect logs)" \
  verbose \
  cukinia_http_request http://localhost:8080/sanitycheck

not cukinia_user baduser

test_id "SWR_001" \
    cukinia_systemd_unit sshd.service
```

---

## 🔄 Conditions & Flow Control

These may also **prefix** any test statement, and can be combined:

- `when "<shell_expr>"` … *test* → run test only if expression returns success
- `unless "<shell_expr>"` … *test* → run test only if expression returns failure (reported as SKIP when not executed)
- `on <result>` → execute statements conditionally on test result (e.g., `on success`, `on failure`)
  - `retry <count> [after <interval>]` → retry a test `count` times with optional interval (e.g., `2s`, `1m`, `3h`, `1d`)

**Examples**

```sh
on_eval_board() { grep -q EVK /sys/firmware/devicetree/base/model; }
on_arm64 { test "$(uname -m)" = "aarch64"; }

when "on_arm64 && !on_eval_board" \
  as "Custom LED controller was probed"  \
    cukinia_test -d /sys/class/leds/customled

on failure retry 3 after 2s \
    cukinia_systemd_unit big-app.service
```

---

## 🧰 Utility Statements

- `cukinia_run_dir <dir>` → run all executables in given directory as individual tests
- `cukinia_conf_include <glob>` → include additional config files, useful for splitting your tests into domain-specific files
- `cukinia_log "<message>"` → log a message to stdout


**Examples**

```sh
cukinia_conf_include /etc/cukinia/conf.d/*.conf

cukinia_log "Starting graphics tests, $cukinia_failures failures so far"
cukinia_run_dir /opt/gfx_tests/
```

---

## 🪪 Logging Customization

For the console output:

- `logging prefix "string"` → set prefix for following test results / cukinia_log outputs

For the JunitXML output:

- `logging class "string"` → set JUnitXML class name for following tests
- `logging suite "string"` → set JUnitXML test suite for following tests

---

## Useful Variables

- `$cukinia_tests` → number of tests attempted
- `$cukinia_failures` → number of tests that failed

## Useful functions

Those shell functions may be useful in your test suite:

- `$(_colorize color_name string)"` → colorize string argument for console display, useful with `cukinia_log` - Most colors have a '2' variant which is brighter
- `$(_ver2int x.y.z)"` → creates integer version of numeric version string, useful for comparing stuff with `cukinia_test`

**Examples**

```sh
cukinia_log "$(_colorize yellow2 "Starting Graphics Test Suite")"

cukinia_test $(_ver2int ${kernel_version}) -ge $(_ver2int 6.6.38)
```

## Environment variables

- `$CUKINIA_ALWAYS_PASS` → if set, every test will succeed

# Advanced Configuration

A Cukinia config file is actually a POSIX shell script that is sourced by
cukinia, so any shell logic can be used in a test file scenario.

This is useful for example to make certain groups of tests depend on preliminary
checks:

```sh
if cukinia_test -x /usr/bin/myapp; then
	cukinia_user myuser
	cukinia_process myapp myuser
	cukinia_http_request http://localhost:8080/testme
else
	cukinia_log "$(_colorize red "myapp not found :(")"
fi

```

# Example cukinia.conf

```sh
cukinia_log "----> Base System Requirements <----"

cukinia_user pipewire
cukinia_group dialout

test_id SYS_033 \
    cukinia_process sshd

test_id SYS_049 \
    cukinia_kthread kaudit


cukinia_log "----> Kernel Requirements <----"

test_id KRN_002 \
  as "Linux kernel version is 6.12 for LTS support" \
    cukinia_kversion 6.12

test_id KRN_044 \
    cukinia_kmod snd_usb_audio


cukinia_log "----> Misc. tests <----"

cukinia_test -f /etc/os-release

test_id SYS_037 \
  as "/etc/os-release contains custom SYSVER= key" \
    cukinia_cmd grep -q '^SYSVER=[0-9\.]+$' /etc/os-release

```

# Development

Cukinia is validated using `bats`. The non-regression tests can be run with:

```sh
git submodule update --init
bats bats/cukinia.bats
```

# License

Cukinia is released under the Apache 2 license.

`Copyright (C) 2017-2025 Savoir-faire Linux, Inc.`
