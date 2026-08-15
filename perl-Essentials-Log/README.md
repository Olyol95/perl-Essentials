# NAME

Essentials::Log - A simple but flexible logging module

# VERSION

version 0.1.2

# SYNOPSIS

    use Essentials::Log;
    use Essentials::Log::Level qw($DEBUG);

    my $log = Essentials::Log->new;

    # log a debug message (filtered out by default)
    $log->debug("You won't see this");

    # log something interesting, including some additional metadata
    $log->info("This is just a drill", {
        job_id => 12345,
    });

    # log a warning
    $log->warn("Watch out for this!");

    # log an error with some additional metadata
    $log->error("This is bad!", {
        trace => ...,
    });

    # alter the log level to include debug messages
    $log->level($DEBUG);

    # set some additional context to be included in all subsequent log lines
    $log->context->{field_name} = $value;

    # inject a custom formatter and writer
    $log = Essentials::Log->new(
        formatter => My::Log::Formatter->new(...),
        writer    => My::Log::Writer->new(...),
    );

    # capture stdout and stderr
    $log->start_capture;

    print("Some message from a third-party module"); # logged via $log->info(...)
    warn("Some warning from an unknown source");     # logged via $log->warn(...)

    # stop capturing
    $log->stop_capture;

# DESCRIPTION

This module provides structured logging capabilities with support for
various severity levels.

# ATTRIBUTES

- `context`

    A hashref containing information that will be included in every log message.

    To keep things simple, you can edit the contents of the hash directly.

        $log->context->{job_id} = '12345';

        $log->info("example message");
        $log->info("another message");

        delete $log->context->{job_id};

        $log->info("final message");

    Is equivalent to:

        $log->info("example message", {
            job_id => 12345,
        });
        $log->info("another message", {
            job_id => 12345,
        });
        $log->info("final message");

- `formatter`

    An instance of [Essentials::Log::Formatter](https://metacpan.org/pod/Essentials%3A%3ALog%3A%3AFormatter).

    Used to format the log messages into a string.

- `level`

    Controls the minimum severity level that is logged.

    Must be a constant defined by [Essentials::Log::Level](https://metacpan.org/pod/Essentials%3A%3ALog%3A%3ALevel).

    Defaults to `$INFO`.

    Available log levels are `$TRACE`, `$DEBUG`, `$INFO`, `$WARN`, `$ERROR`, in that order.

- `writer`

    An instance of [Essentials::Log::Writer](https://metacpan.org/pod/Essentials%3A%3ALog%3A%3AWriter).

    Used to write the formatted string to the log destination.

- `should_capture`

    Boolean. When true, any writes to `STDOUT` and `STDERR` are
    captured and redirected via the logger.

    Defaults to false.

    `STDOUT` is sent via `<$log-`info(...)>>

    `STDERR` is sent via `<$log-`warn(...)>>

    You can toggle this on and off later via `start_capture`
    and `stop_capture`.

    Capturing is automatically disabled once the log object
    goes out of scope.

# METHODS

- `debug($message, $data)`

    Write a `$message` at the `$TRACE` severity level.

    `$data` is an optional hashref containing key-value pairs
    to include in the log line.

    Note that these messages will be filtered out by the default active `level`.

- `error($message, $data)`

    Write a `$message` at the `$ERROR` severity level.

    `$data` is an optional hashref containing key-value pairs
    to include in the log line.

- `info($message, $data)`

    Write a `$message` at the `$INFO` severity level.

    `$data` is an optional hashref containing key-value pairs
    to include in the log line.

- `trace($message, $data)`

    Write a `$message` at the lowest (`$TRACE`) severity level.

    `$data` is an optional hashref containing key-value pairs
    to include in the log line.

    Note that these messages will be filtered out by the default active `level`.

- `warn($message, $data)`

    Write a `$message` at the `$WARN` severity level.

    `$data` is an optional hashref containing key-value pairs
    to include in the log line.

- `start_capture`

    Starts capturing writes to `STDOUT` and `STDERR` and redirects them.

    `STDOUT` is sent via `<$log-`info(...)>>

    `STDERR` is sent via `<$log-`warn(...)>>

    Capturing is automatically disabled once the log object goes out of scope.

- `stop_capture`

    Stops capturing writes to `STDOUT` and `STDERR`.

- `is_capturing`

    Returns true if the logger is currently capturing `STDOUT` and `STDERR`.

# SEE ALSO

- [Essentials::Log::Level](https://metacpan.org/pod/Essentials%3A%3ALog%3A%3ALevel)
- [Essentials::Log::Formatter](https://metacpan.org/pod/Essentials%3A%3ALog%3A%3AFormatter)
- [Essentials::Log::Writer](https://metacpan.org/pod/Essentials%3A%3ALog%3A%3AWriter)

# AUTHOR

Oliver Youle <oliver@youle.io>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Oliver Youle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
