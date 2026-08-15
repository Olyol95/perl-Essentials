package Essentials::Log;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use Safe::Isa;

use Essentials::Log::Capture;
use Essentials::Log::Formatter;
use Essentials::Log::Level qw(:constants);
use Essentials::Log::Writer;

# ABSTRACT: A simple but flexible logging module

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module provides structured logging capabilities with support for
various severity levels.

=head1 ATTRIBUTES

=over

=item C<context>

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

=cut

has context => (
    is      => 'ro',
    default => sub { {} },
);

=item C<formatter>

An instance of L<Essentials::Log::Formatter>.

Used to format the log messages into a string.

=cut

has formatter => (
    is      => 'ro',
    default => sub {
        Essentials::Log::Formatter->new
    },
);

=item C<level>

Controls the minimum severity level that is logged.

Must be a constant defined by L<Essentials::Log::Level>.

Defaults to C<$INFO>.

Available log levels are C<$TRACE>, C<$DEBUG>, C<$INFO>, C<$WARN>, C<$ERROR>, in that order.

=cut

has level => (
    is      => 'rw',
    default => sub {
        $INFO
    },
);

=item C<writer>

An instance of L<Essentials::Log::Writer>.

Used to write the formatted string to the log destination.

=cut

has writer => (
    is      => 'ro',
    default => sub {
        Essentials::Log::Writer->new
    },
);

=item C<should_capture>

Boolean. When true, any writes to C<STDOUT> and C<STDERR> are
captured and redirected via the logger.

Defaults to false.

C<STDOUT> is sent via C<<$log->info(...)>>

C<STDERR> is sent via C<<$log->warn(...)>>

You can toggle this on and off later via C<start_capture>
and C<stop_capture>.

Capturing is automatically disabled once the log object
goes out of scope.

=cut

sub BUILD {
    my ($self, $args) = @_;

    $self->start_capture if $args->{should_capture};
}

sub DEMOLISH {
    my $self = shift;

    $self->stop_capture;
}

=back

=head1 METHODS

=over

=item C<debug($message, $data)>

Write a C<$message> at the C<$TRACE> severity level.

C<$data> is an optional hashref containing key-value pairs
to include in the log line.

Note that these messages will be filtered out by the default active C<level>.

=cut

sub debug {
    my ($self, @args) = @_;

    $self->_write($DEBUG, @args);
}

=item C<error($message, $data)>

Write a C<$message> at the C<$ERROR> severity level.

C<$data> is an optional hashref containing key-value pairs
to include in the log line.

=cut

sub error {
    my ($self, @args) = @_;

    $self->_write($ERROR, @args);
}

=item C<info($message, $data)>

Write a C<$message> at the C<$INFO> severity level.

C<$data> is an optional hashref containing key-value pairs
to include in the log line.

=cut

sub info {
    my ($self, @args) = @_;

    $self->_write($INFO, @args);
}

=item C<trace($message, $data)>

Write a C<$message> at the lowest (C<$TRACE>) severity level.

C<$data> is an optional hashref containing key-value pairs
to include in the log line.

Note that these messages will be filtered out by the default active C<level>.

=cut

sub trace {
    my ($self, @args) = @_;

    $self->_write($TRACE, @args);
}

=item C<warn($message, $data)>

Write a C<$message> at the C<$WARN> severity level.

C<$data> is an optional hashref containing key-value pairs
to include in the log line.

=cut

sub warn {
    my ($self, @args) = @_;

    $self->_write($WARN, @args);
}

=item C<start_capture>

Starts capturing writes to C<STDOUT> and C<STDERR> and redirects them.

C<STDOUT> is sent via C<<$log->info(...)>>

C<STDERR> is sent via C<<$log->warn(...)>>

Capturing is automatically disabled once the log object goes out of scope.

=cut

sub start_capture {
    my $self = shift;

    return if $self->is_capturing;

    tie(
        *STDOUT, 'Essentials::Log::Capture',
        stream => 'stdout',
        log    => $self,
    );
    tie (
        *STDERR, 'Essentials::Log::Capture',
        stream => 'stderr',
        log    => $self,
    );

    $self->{_capturing} = 1;
}

=item C<stop_capture>

Stops capturing writes to C<STDOUT> and C<STDERR>.

=cut

sub stop_capture {
    my $self = shift;

    return unless $self->is_capturing;

    foreach my $handle (\*STDOUT, \*STDERR) {
        next unless tied(*$handle);
        tied(*$handle)->flush;
        untie(*$handle);
    }

    $self->{_capturing} = 0;
}

=item C<is_capturing>

Returns true if the logger is currently capturing C<STDOUT> and C<STDERR>.

=cut

sub is_capturing {
    my $self = shift;

    return $self->{_capturing} || 0;
}

=back

=cut

sub _write {
    my ($self, $level, $message, $data) = @_;

    if ($level < $self->level) {
        return;
    }

    $data //= {};

    if ($self->context) {
        $data = { %{ $self->context }, %$data };
    }

    if ($message->$_isa('Essentials::Exception')) {
        if ($DEBUG >= $self->level) {
            $data->{stack_trace} = $message->stack_trace;
        }
        $message = $message->message;
    }

    $self->writer->write(
        $self->formatter->format(
            $level,
            $message,
            $data,
        ),
    );
}

=head1 SEE ALSO

=over

=item L<Essentials::Log::Level>

=item L<Essentials::Log::Formatter>

=item L<Essentials::Log::Writer>

=back

=cut

1;
