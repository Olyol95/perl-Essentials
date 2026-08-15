# NAME

Essentials::Script - A Moo role for wrapping scripts as modules

# VERSION

version 0.2.0

# SYNOPSIS

In `My/Application.pm`

    package My::Application;

    use Moo;

    with 'Essentials::Script';

    has 'example_string' => (
        ...
    );

    has 'example_int' => (
        ...
    );

    has 'example_array' => (
        ...
    );

    has 'example_bool' => (
        ...
    );

    sub run {
        # implementation here...
    }

    1;

In `my-script.pl`

    #!/usr/bin/env perl

    use My::Application;
    use Essentials::Script::Heartbeat::StampFile;

    My::Application->new_with_opts(
        example_string => 'example-string=s',
        example_int    => 'baz=i',
        example_array  => 'array-item=s@',
        example_bool   => 'bool',
    )
    ->with_heartbeat(
        Essentials::Script::Heartbeat::StampFile->new(
            file_name => '/path/to/stamp-file.stamp',
        ),
    )
    ->run;

# DESCRIPTION

This package provides a [Moo::Role](https://metacpan.org/pod/Moo%3A%3ARole) for wrapping a [Moo](https://metacpan.org/pod/Moo) object with a
`new_with_opts` constructor that populates attributes from command-line
options via [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) argument strings.

In addition to your own custom arguments, this role provides the following
CLI options by default:

- `log-level <level>`

    The verbosity level to use for logging. Defaults to `warn`.

    Valid options are `trace`, `debug`, `info`, `warn`, `error`.

- `help`

    Displays usage text.

# ATTRIBUTES

This role also provides some default attributes.

- `log`

    An instance of [Essentials::Log](https://metacpan.org/pod/Essentials%3A%3ALog).

    The log level can be configured via the `log-level` CLI argument,
    and will default to `warn`.

- `heartbeat`

    An instance of [Essentials::Script::Heartbeat](https://metacpan.org/pod/Essentials%3A%3AScript%3A%3AHeartbeat), which will be notified
    after each successful execution of the `run` method.

    Defaults to [Essentials::Script::Heartbeat::None](https://metacpan.org/pod/Essentials%3A%3AScript%3A%3AHeartbeat%3A%3ANone).

# REQUIRED METHODS

The following methods require implementation in order to compose the role.

- `run`

    The entry point for your script.

    There are no restrictions on the parameters that can be passed to this method,
    though it is recommended that you use attributes instead to keep as much logic
    inside a module as possible so that it can be more easily tested.

# STATIC METHODS

- `new_with_opts(%opts)`

    Constructs a new instance of your class with attributes populated from the
    command-line options provided by the caller.

    `%opts` should be a hash that maps attribute names to [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) argument
    strings that will be used to populate the value of the provided attribute.

    For example, a string attribute, `full_name`,can be passed through from the
    command line like so:

        My::Application->new_with_opts(
            full_name => 'full-name=s',
        );

    The caller would then invoke the script like so:

        ./my-script.pl --full-name=Oliver Youle

    See the documentation for [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) for a complete description of the
    available options.

    Arrays must be provided using the array reference syntax, `array-param=s@`.

# SEE ALSO

- [Essentials::Script::Service](https://metacpan.org/pod/Essentials%3A%3AScript%3A%3AService)

# AUTHOR

Oliver Youle <oliver@youle.io>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Oliver Youle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
