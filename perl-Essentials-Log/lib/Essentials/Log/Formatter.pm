package Essentials::Log::Formatter;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use POSIX qw(strftime);
use Time::HiRes qw(gettimeofday);

# ABSTRACT: Formats log lines in a structured manner

=head1 SYNOPSIS

  use Essentials::Log::Formatter;
  use Essentials::Log::Level qw($INFO);

  # use the default config
  my $formatter = Essentials::Log::Formatter->new;

  my $line = $formatter->format($INFO, "This is a message", key => 'value');

  # choose elements to include
  $formatter = Essentials::Log::Formatter->new(
      include_level => 1,
      include_pid   => 1,
      include_prog  => 1,
      include_time  => 1,
  );

  # [YYYY-MM-DD HH:MM:SS.000000 UTC] <1234> my-perl-program: [info] msg="This is a message" key="value"
  my $line = $formatter->format($INFO, "This is a message", key => 'value');

=head1 DESCRIPTION

A module for formatting log lines in a structured manner, for use with L<Essentials::Log>. 

=head1 ATTRIBUTES

=over

=item C<include_level>

A boolean, which when set to true will include the log level in the log line.

Defaults to true.

=cut

has include_level => (
    is      => 'ro',
    default => 1,
);

=item C<include_pid>

A boolean, which when set to true will include the current process ID in the log line.

Defaults to true, unless the process is running under systemd.

=cut

has include_pid => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return $self->_is_systemd ? 0 : 1;
    },
);

=item C<include_pid>

A boolean, which when set to true will include the name of the current process in the log line.

Defaults to true, unless the process is running under systemd.

=cut

has include_prog => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return $self->_is_systemd ? 0 : 1;
    },
);

=item C<include_time>

A boolean, which when set to true will include the current time in UTC in the log line.

The time is formatted as C<YYYY-MM-DD HH:MM:SS.Micros>.

Defaults to true, unless the process is running under systemd.

=cut

has include_time => (
    is      => 'lazy',
    default => sub {
        my $self = shift;
        return $self->_is_systemd ? 0 : 1;
    },
);

=back

=head1 METHODS

=over

=item C<format($level, $message, $data)>

Returns a formatted log line.

C<$level> should be a valid L<Essentials::Log::Level>.

C<$message> should contain the message to log.

C<$data> is an optional hashref that should contain any additional key-value
pairs to include in the log line.

=cut

sub format {
    my ($self, $level, $message, $data) = @_;

    my @line;

    if ($self->include_time) {
        my ($seconds, $microseconds) = gettimeofday();
        my $timestamp = strftime('[%F %T.## UTC]', gmtime($seconds));
        my $microsecs = sprintf('%06d', $microseconds);
        $timestamp =~ s/##/$microsecs/;
        push @line, $timestamp;
    }

    if ($self->include_pid) {
        push @line, "<$$>";
    }

    if ($self->include_prog) {
        my $prog = $0;
        $prog =~ s/.*\///g;
        push @line, "$prog:";
    }

    if ($self->include_level) {
        push @line, "[$level]";
    }

    chomp($message);
    push @line, $self->_format_values(msg => $message);

    if ($data && %$data) {
        push @line, $self->_format_values(%$data);
    }

    return join(' ', @line);
}

sub _is_systemd {
    my $journal_stream = $ENV{JOURNAL_STREAM};
    unless ($journal_stream) {
        return;
    }

    my ($device, $inode) = stat '/dev/stderr';
    unless (defined $device && defined $inode) {
        return;
    }

    my $stderr_stream = join ':', $device, $inode;

    return $journal_stream eq $stderr_stream;
}

sub _format_values {
    my ($self, %values) = @_;

    my @line;

    while (my ($key, $value) = each %values) {
        $value = $self->_format_value($value);
        push @line, "$key=\"$value\"";
    }

    return join(' ', sort @line);
}

sub _format_value {
    my ($self, $value) = @_;

    $value =~ s/\n/\\n/gm;
    $value =~ s/"/\\"/g;

    return $value;
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Log>

=item L<Essentials::Log::Level>

=item L<Essentials::Log::Writer>

=back

=cut

1;
