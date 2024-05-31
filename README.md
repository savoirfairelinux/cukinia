![cukinia logo](./doc/cukinia_logo.png?raw=true)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Cukinia - a Linux firmware validation framework

Cukinia is designed to help Linux-based embedded firmware developers
run simple system-level validation tests on their firmware.

Cukinia integrates well with embedded firmware generation frameworks
such as Buildroot and Yocto, and can be run manually or by your
favourite continuous integration framework.

## Project objectives

Cukinia works if it offers the following value:

* It is very simple to use
* It requires no dependencies other than busybox
* It integrates easily with CI/CD pipelines
* It helps developers creating better software

## Usage

``cukinia [options] [config file]``

Useful options:

* `-f junitxml`: format results as JUnit XML (useful for Jenkins & others)
* `-f csv`: format results as CSV text
    * `--no-header`: omit CSV header line
* `-o file`: output results to file instead of stdout

## Screenshot

![Screenshot](doc/screenshot.png)

## Basic config

To run Cukinia, create a configuration describing your tests, and
invoke it. By default, cukinia reads ``/etc/cukinia/cukinia.conf``.
Alternatively, a config file can be passed to cukinia as its argument.

A cukinia config file supports the following statements:

### Test statements

* ``cukinia_user <username>``: Validates that user exists
* ``cukinia_group <groupname>``: Validates that group exists
* ``cukinia_user_memberof <username> <group...>``: Validate that user is member of groups
* ``cukinia_kmod <kernel module>``: Validates that kernel module is loaded
* ``cukinia_kconf <kernel config symbol> <y|m|n>``: Validates that kernel config
  symbol is set to given tristate value
* ``cukinia_kversion <version>``: Validate kernel version (only check maj.min, e.g 5.14)
* ``cukinia_process <pname> [user]``: Validates that process runs (optional user)
* ``cukinia_kthread <pname>``: Validates that kernel thread runs
* ``cukinia_python_pkg <pkg>``: Validates that Python package is installed
* ``cukinia_test <expr>``: Validates that test(1) expression is true
* ``cukinia_http_request <url>``: Validates that url returns a 200 code
* ``cukinia_cmd <command>``: Validates that arbitrary command returns true
* ``cukinia_cmdline <param[=val_regex]>``: Validates kernel cmdline contains param (optional value)
* ``cukinia_listen4 <proto> <port>``: Validates that tcp/udp port is open locally
* ``cukinia_mount <source> <mount point> [fstype] [options]``: Validate the
  presence of a mount on the system
* ``cukinia_symlink <link> <target>``: Validate the target of a symlink
* ``cukinia_systemd_failed``: Raise a failure if a systemd unit is in failed state
* ``cukinia_systemd_unit <unit>``: Validate systemd unit is active
* ``cukinia_i2c <bus_number> [device_address] [driver_name]``: This checks i2c bus or (optional) device, and (optionally) verifies it uses the indicated driver
* ``cukinia_gpio_libgpiod -i [input_pins] -l [output_low_pins] -h [output_high_pins]
  -g [gpiochip](default:gpiochip0)``: Validate the gpio configuration via libgpiod
  (ex: cukinia_gpio_libgpiod -i "0 3 4" -l "10" -h "2 50" -g gpiochip1)
* ``cukinia_gpio_sysfs -i [input_pins] -l [output_low_pins] -h [output_high_pins]
  -g [gpiochip](default:gpiochip0)``: Validate the gpio configuration via sysfs
  (ex: cukinia_gpio_sysfs -i "20 34" -h "3 99 55")
* ``cukinia_knoerror <priority>``: Validate kernel has booted without important
  errors (the priority argument is the log level number to check)
* ``cukinia_sysctl <parameter> <value>``: Validate kernel sysctl parameter is set to value
* ``cukinia_netif_has_ip <interface> [-4|-6] [flags]``: Validate that interface has ip config parameters
  * example: `cukinia_netif_has_ip eth0 -4 dynamic`
  * example: `cukinia_netif_has_ip eth0 -6 "scope global"`
* ``cukinia_netif_is_up <interface>``: Validate network interface state is up
* ``cukinia_dns_resolve <hostname>``: Validate that hostname can be resolved
* ``not``: Can prefix any test to invert the issue it will produce (a
  ``[!]`` is appended to the default test description)
* ``verbose``: Can prefix any test to preserve stdout/stderr
* ``as <string>``: Can prefix any test to change its textual description
* ``id <string>``: Can prefix any test to add a test id in the different outputs

### Condition statements

* `when <condition>`: Can prefix any test to `<condition>` it
* `unless <condition>`: Just like `when`, but the opposite

If the condition is not met, the test status will be reported as SKIP.

A few examples using `when` and `unless`:
``` bash
on_eval_board() { grep -q EVK /sys/firmware/devicetree/base/model; }
arch_is_arm64() { test "$(uname -m)" = "aarch64"; }

unless "on_eval_board" \
  as "Custom LED controller was detected" \
    cukinia_test -d /sys/class/leds/superled

when "arch_is_arm64" \
  unless "on_eval_board" \
    cukinia_kmod some_driver 
```

### Utility statements

* ``cukinia_conf_include <files>``: Includes files as additional config files
* ``cukinia_run_dir <directory>``: Runs all executables in directory as individual tests
* ``cukinia_log <message>``: Logs message to stdout
* ``_ver2int <version>``: Convert numeric version string to int, for use with
  e.g. ``cukinia_test $(_ver2int ${kernel_version}) -gt $(_ver2int 4.19.7)``

### Logging customization

* ``logging prefix "string"``: prefix logs with "string"
* ``logging class "string"``: change the junitxml class name to "string" for the next tests
* ``logging suite "string"``: change the junitxml test suite to "string" for the next tests

### Useful variables

* ``$cukinia_tests``: number of tests attempted
* ``$cukinia_failures``: number of tests that failed

### Environment variables

* ``$CUKINIA_ALWAYS_PASS``: if set, every test will succeed

### Example cukinia.conf

```shell

# Ensure our basic users are present
cukinia_user appuser1
cukinia_user appuser2

# This should always be the case
cukinia_test -f /etc/passwd

# If this user exists, then something went wrong
not cukinia_user baduser

# Those config snippets are deployed by our packages
cukinia_conf_include /etc/cukinia/conf.d/*.conf

# Is our embedded webservice up?
as "Checking webapp" cukinia_http_request http://localhost:8080/sanitycheck

# Run executable tests for myapp1
cukinia_run_dir /etc/cukinia/myapp1.d/

# Check for misc. mount points
cukinia_mount sysfs /sys
cukinia_mount /dev/sda1 /boot ext4 rw sync

# Check for ssh and dns servers
cukinia_listen4 tcp 22
cukinia_listen4 udp 53

# Check the link interfaces point to /tmp/interfaces
cukinia_symlink /etc/network/interfaces /tmp/interfaces

# Add a id linked to the test
id "SWR_001" as "Checking systemd units" cukinia_systemd_failed

# End
cukinia_log "ran $cukinia_tests tests, $cukinia_failures failures"
```

## More advanced config

A config file is actually a POSIX shell script that is sourced by
cukinia, so any logic can be used in a test file scenario. This is
useful for example to make certain groups of tests depend on
preliminary checks:

```shell

if cukinia_test -x /usr/bin/myapp; then
	cukinia_user myuser
	cukinia_process myapp myuser
	cukinia_http_request http://localhost:8080/testme
else
	cukinia_log "$(_colorize red "myapp not found :(")"
fi

```

## License

`Copyright (C) 2017-2024 Savoir-faire Linux, Inc.`

Cukinia is released under the Apache 2 license.
