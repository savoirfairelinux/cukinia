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

## Basic config

To run Cukinia, create a configuration describing your tests, and
invoke it.

By default, cukinia reads ``/etc/cukinia/cukinia.conf`` and executes
all executable tests in ``/etc/cukinia/tests.d/``.

A cukinia config file supports the following statements:

### Test statements

* ``cukinia_user <username>``: Validates that user exists
* ``cukinia_process <pname> [user]``: Validates that process runs (as user)
* ``cukinia_python_pkg <pkg>``: Validates that Python package is available
* ``cukinia_http_request <url>``: Validates that url returns a 200-type error code

### Utility statements

* ``cukinia_run_dir <directory>``: Runs all executables in directory as individual tests
* ``cukinia_conf_include <files>``: Includes files as additional config files
* ``cukinia_log <message>``: Logs message to stdout

### Example

```shell

# Ensure our basic users are present
cukinia_user application1
cukinia_user application2

# Those config snippets are deployed by our packages
cukinia_conf_include /etc/cukinia/conf.d/*.conf

# Is our embedded webservice up?
cukinia_http_request http://localhost:8080/sanitycheck
```

## License

Cukinia is released under the Apache 2 license. In addition, it is
available under the GNU General Public License, version 3.
