# xdebug-setup
A shell script to automatically download and install xdebug on ubuntu. While it is possible to use this script to manually install any version of xdebug, this script is intended to setup xdebug version 3.0 and higher. For lower versions of xdebug it is recommended to use apt packages instead. If installing a version of xdebug lower than 3.0, you will need to modify the contents of xdebug.ini that gets placed in your mods-available folder to conform to the older config.

# Settings
This script installs xdebug with the following settings by default:
```
xdebug.mode = debug,trace
xdebug.client_port = 9003
xdebug.start_with_request = trigger
xdebug.output_dir = /tmp/xdebug
xdebug.log_level = 0
```

There is no particular reason for this other than my own xdebug preferences. These may be customized after installation.

# dbgpProxy
This script will automatically install dbgpProxy and supervisor. Supervisor will be configured with the following settings to autostart and maintain dbgpProxy:
```
[program:dbgpProxy]
command=/usr/bin/dbgpProxy -s 127.0.0.1:9003
autostart=true
autorestart=true
stderr_logfile=/var/log/dbgpProxy.error
stdout_logfile=/var/log/dbgpProxy.log
```

dbgpProxy installation can be skipped if undesired by passing the optional -n (no proxy) flag.

# Usage

Default setup (uses xdebug 3.0.3)

`sudo ./xdebug_setup.sh`

Specify xdebug version setup

`sudo ./xdebug_setup.sh -v 3.1.4`

# Warranty
This script comes with NO WARRANTY or implied warranty as defined by LICENSE. I intend to provide no support, use at your own risk.
