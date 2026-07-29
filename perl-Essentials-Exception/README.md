# NAME

Essentials::Exception - A throwable exception object with a stack trace.

# VERSION

version 0.1.1

# SYNOPSIS

    use Try::Tiny;
    use Essentials::Exception qw(throw);

    try {
        throw "This wasn't supposed to happen!";
    }
    catch {
        # access the error message
        my $message = $_->message;

        # access the stack trace
        my $trace = $_->stack_trace;

        # print the message like normal
        say $_;
    };

# DESCRIPTION

This module extends [Throwable](https://metacpan.org/pod/Throwable) to provide a convenient exception
containing both a message and a stack trace.

# METHODS

- `message`

    Returns a description of the exception that has been thrown.

- `stack_trace`

    Returns a string containing the state of the call stack at the
    point that the exception was thrown.

# EXPORTED FUNCTIONS

- `throw ($message)`

    Dies with a new Essentials::Exception object containing the provided message.

# SEE ALSO

- [Throwable](https://metacpan.org/pod/Throwable)

# AUTHOR

Oliver Youle <oliver@youle.io>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Oliver Youle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
