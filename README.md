# log4bash

Let's face it - plain old **echo** just doesn't cut it.  **log4bash** is an attempt to have better logging for Bash scripts (i.e. make logging in Bash suck less).

## Original author

Fred Palmer

## Using log4bash

**source** the *log4bash.sh* script at the beginning of any Bash program.

``` bash

    #!/usr/bin/env bash
    source log4bash.sh

    log "This is regular log message... log and log_info do the same thing";

    log_warning "Luke ... you turned off your targeting computer";
    log_info "I have you now!";
    log_success "You're all clear kid, now let's blow this thing and go home.";
    log_error "One thing's for sure, we're all gonna be a lot thinner.";

    # If you have figlet installed -- you'll see some big letters on the screen!
    log_captains "What was in the captain's toilet?";

    # If you have the "espeak" command (e.g. on Linux)
    log_speak "Resistance is futile";

```

## An Overview of log4bash


### Colorized Output

![(https://img.skitch.com/20110526-46e6ng8hj11pshw2s5my7e841.jpg)](https://img.skitch.com/20110526-46e6ng8hj11pshw2s5my7e841.jpg "Colorized Output")

### Logging Levels

* **log_info**

    Prints an "INFO" level message to stdout with the timestamp of the occurrence.

* **log_warning**

    Prints a "WARNING" level message to stdout with the timestamp of the occurrence.

* **log_success**

    Prints a "SUCCESS" level message to stdout with the timestamp of the occurrence.

* **log_error**

    Prints an "ERROR" level message to stdout with the timestamp of the occurrence.

### Special Logging Abilities

* **log_speak**

    On the Linux platform this will use the espeak command to echo the command to the current audio output device.

* **log_captains**

    If the *figlet* program is installed this will print out an ascii-art depiction of the phrase passed to the function.

* **log_campfire**

    Posts a message to your campfire configured by setting the variables for **CAMPFIRE_API_AUTH_TOKEN** and **CAMPFIRE_NOTIFICATION_URL**.

### logz.io Integration

This fork of log4ash.sh may also automatically post log messages to your logz.io account.  Requires setting **LOGZ_TOKEN** prior to any debugging messages.  The "level" of the log entry is set to the appropriate level based on the `log_debug`, `log_info`, etc log commands.

* NOTE: This feature requires awk to prepare the message.  This should not be an issue on most systems, as it's already included

By default, includes a "meta" JSON structure that can be configured with environment variables.  This allows advanced searching with logz.io.  By default, the standard JSON included in each log entry is:

    "meta": {
      "level": "DEBUG",
      "type": "bash"
    }

To include additional fields in this object, simply export a variable as follows:

    export LOGZ_META_env=$NODE_ENV

The resultant JSON would now be:

    "meta": {
      "env": "production",
      "level": "DEBUG",
      "type": "bash"
    }

Using this log message:

    log_debug "Migrating database to latest version"

creates this log in logz.io:

![logz.io screenshot](https://ibin.co/3MY2Qhc4G0Ef.png "logz.io Screenshot")


Configuration Variables

* `LOGZ_SCHEME` -- default: "http"
* `LOGZ_HOST` -- default: "listener.logz.io"
* `LOGZ_PORT` -- default: "8070"
* `LOGZ_META_type` -- default: "bash"
* `LOGZ_ENABLE` -- default: "no"


### Other Useful Tidbits

* **SCRIPT_ARGS**

    A global array of all the arguments used to create run your script

* **SCRIPT_NAME**

    The script name (sometimes tricky to get right depending on how one invokes a script).

* **SCRIPT_BASE_DIR**

    The script's base directory which is not always the current working directory.



