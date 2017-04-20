# Cukinia firmware validation framework

Cukinia is designed to help Linux-based embedded firmware developers
run simple validation tests on their firmware.

Cukinia integrates well with embedded firmware generation frameworks
such as Buildroot and Yocto, and can be run manually or by your
favourite continuous integration framework.

## Project objectives

Cukinia works if it offers the following value:

* It is very simple to use
* It requires no dependencies other than busybox
* It helps developers creating better software

## Usage

``cukinia [config file]``

## Basic config

To run Cukinia, create a configuration describing your tests, and
invoke it. By default, cukinia reads ``/etc/cukinia/cukinia.conf``.
Alternatively, a config file can be passed to cukinia as its argument.

A cukinia config file supports the following statements:

### Test statements

* ``cukinia_user <username>``: Validates that user exists
* ``cukinia_process <pname> [user]``: Validates that process runs (optional user)
* ``cukinia_python_pkg <pkg>``: Validates that Python package is installed
* ``cukinia_http_request <url>``: Validates that url returns a 200 code
* ``cukinia_mount  <source> <mount point> [options]``: Validate the presence of a mount on the system
* ``not``: Can prefix any test to invert the issue it will produce
* ``verbose``: Can prefix any test to preserve stdout/stderr

### Utility statements

* ``cukinia_conf_include <files>``: Includes files as additional config files
* ``cukinia_run_dir <directory>``: Runs all executables in directory as individual tests
* ``cukinia_log <message>``: Logs message to stdout

### Useful variables

* ``$cukinia_tests``: number of tests attempted
* ``$cukinia_failures``: number of tests that failed

### Example cukinia.conf

```shell

# Ensure our basic users are present
cukinia_user appuser1
cukinia_user appuser2

# If this user exists, then something went wrong
not cukinia_user baduser

# Those config snippets are deployed by our packages
cukinia_conf_include /etc/cukinia/conf.d/*.conf

# Is our embedded webservice up?
cukinia_http_request http://localhost:8080/sanitycheck

# Run executable tests for myapp1
cukinia_run_dir /etc/cukinia/myapp1.d/

# Check for root mounting point on / in read write mode
cukinia_mount sysfs /sys rw

# End
cukinia_log "ran $cukinia_tests tests, $cukinia_failed failures"
```

## License

Cukinia is released under the Apache 2 license. In addition, it is
available under the GNU General Public License, version 3.
