package Essentials::Log::Capture;

use v5.26;
use strictures 2;

# VERSION

use Scalar::Util qw(weaken);

# ABSTRACT: A tied handle for capturing logging streams

=head1 SYNOPSIS

  use Essentials::Log::Capture;
  use Essentials::Log;

  my $log = Essentials::Log->new;

  tie(
      *STDOUT, 'Essentials::Log::Capture',
      stream => 'stdout',
      log    => $log,
  );

  say "This is now captured"; # re-routed via $log->info(...)

  tie(
      *STDERR, 'Essentials::Log::Capture',
      stream => 'stderr',
      log    => $log,
  );

  warn "This is now captured"; # re-routed via $log->warn(...)

=head1 DESCRIPTION

This is an internal module meant to be used with Essentials::Log
that enables capturing of output streams such as STDOUT and STDERR
such that they can be re-routed via the structured logging methods
exposed by Essentials::Log.

Instead of using this directly, see the C<should_capture> attribute
of L<Essentials::Log> instead.

Note that output is only flushed to the log on each new line.

=head1 ATTRIBUTES

=over

=item C<log>

An instance of L<Essentials::Log> to re-route the handle to.

Required.

=item C<stream>

Stream identifier as a string, defaults to C<stdout>.

C<stdout> will be redirected to C<< $log->info(...) >>

Everything else will be redirected to C<< $log->warn(...) >>

=back

=cut

sub TIEHANDLE {
    my ($class, %args) = @_;

    die "No log provided" unless $args{log};

    my $self = bless {
        log    => $args{log},
        stream => $args{stream} // 'stdout',
        buffer => '',
    }, $class;

    weaken($self->{log});

    return $self;
}

=head1 METHODS

=over

=item C<flush>

Flushes any buffered output to the log.

=cut

sub flush {
    my $self = shift;

    return unless length $self->{buffer} > 0;

    my $line = $self->{buffer};
    $self->{buffer} = '';
    $self->_log($line);
}

=item C<PRINT>

Called when the tied handle is printed to via C<say()> or C<print()>.

Calls to C<print()> are flushed to the log on each new line.

=cut

sub PRINT {
    my ($self, @args) = @_;

    my $field_separator  = defined $, ? $, : '';
    my $record_separator = defined $\ ? $\ : '';

    $self->_write(
        join($field_separator, @args) . $record_separator
    );
}

=item C<PRINTF>

Called when the tied handle is printed to with the C<printf()> function.

Calls are flushed to the log on each new line.

=cut

sub PRINTF {
    my ($self, $fmt, @args) = @_;

    $self->_write(
        sprintf($fmt, @args)
    );
}

=item C<WRITE>

Called when the tied handle is written to via C<syswrite()>.

Calls are flushed to the log on each new line.

=cut

sub WRITE {
    my ($self, $buffer, $length, $offset) = @_;

    $offset //= 0;
    $length //= length $buffer;

    $self->_write(
        substr($buffer, $offset, $length)
    );

    return $length;
}

=item C<BINMODE>

Called when C<binmode()> is used on the tied handle.

Always returns 1.

=cut

sub BINMODE {
    return 1;
}

=item C<OPEN>

Called when C<open()> is used on the tied handle.

Always returns 1.

=cut

sub OPEN {
    return 1;
}

=item C<CLOSE>

Called when C<close()> is used on the tied handle.

Flushes the buffer to the log.

Always returns 1.

=cut

sub CLOSE {
    my $self = shift;

    $self->flush;

    return 1;
}

=item C<FILENO>

Called when C<fileno()> is used on the tied handle.

Always returns -1.

=cut

sub FILENO {
    return -1;
}

=item C<DESTROY>

Called when the tied handle goes out of scope.

The contents of the buffer will be flushed prior to destruction.

=cut

sub DESTROY {
    my $self = shift;

    $self->flush;
}

=back

=cut

# write the buffer to the log, splitting on new lines
sub _write {
    my ($self, $string) = @_;

    return unless length $string > 0;

    $self->{buffer} .= $string;

    while ((my $new_line = index($self->{buffer}, "\n")) >= 0) {
        my $line = substr($self->{buffer}, 0, $new_line, '');     # take up to the new line
        substr($self->{buffer}, 0, 1, '');                        # drop the new line
        $self->_log($line);
    }
}

# log a line, stdout is logged at info, everything else at warn
sub _log {
    my ($self, $line) = @_;

    if ($self->{stream} eq 'stdout') {
        $self->{log}->info($line);
        return;
    }

    $self->{log}->warn($line);
}

=head1 SEE ALSO

=over

=item L<Essentials::Log>

=item L<perltie>

=back

=cut


1;
