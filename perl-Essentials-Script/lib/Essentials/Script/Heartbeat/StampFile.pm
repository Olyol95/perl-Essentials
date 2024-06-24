package Essentials::Script::Heartbeat::StampFile;

use v5.26;
use strictures 2;

# VERSION

use File::Spec;
use Moo;

with 'Essentials::Script::Heartbeat';

# ABSTRACT: A heartbeat module that touches a stamp file when notified

=head1 SYNOPSIS

  use Essentials::Script::Heartbeat::StampFile;

  my $heartbeat = Essentials::Script::Heartbeat::StampFile->new(
      file_name => '/path/to/stamp-file.stamp',
  );

  # do some work

  # notify that we're still alive by touching the stamp file
  $heartbeat->notify;

=head1 DESCRIPTION

This package provides a heartbeat handler for instances of L<Essentials::Script>
and L<Essentials::Script::Service> which touches a file when notified.

The last time that the file was touched can then be monitored by a health check.

=head1 ATTRIBUTES

=over

=item C<file_name>

A string containing the path to the file that will be touched.

Defaults to a tempfile of the form C<E<lt>process-nameE<gt>.stamp>

=cut

has file_name => (
    is      => 'ro',
    default => sub {
        my $process_name = $0 =~ s/[^a-z0-9]/-/ir;
        return File::Spec->catfile(
            File::Spec->tmpdir,
            $process_name . '.stamp'
        );
    },
);

=item C<unlink_on_exit>

When set to true, the stamp file will be deleted once the heartbeat
object moves out of scope (e.g. on process exit).

Defaults to false.

=cut

has unlink_on_exit => (
    is      => 'ro',
    default => 0,
);

sub DEMOLISH {
    my $self = shift;

    if ($self->unlink_on_exit) {
        unlink $self->file_name or warn "Failed to unlink stamp file: $!";
    }
}

=back

=head1 METHODS

=over

=item C<notify>

Consumes the notification and touches the file defined by C<file_name>.

If the file doesn't exist, it will be created.

Returns true if the operation was successful, false otherwise.

=cut

sub notify {
    my $self = shift;

    my $now = time;
    return 1 if utime($now, $now, $self->file_name);

    open my $fh, '>>', $self->file_name or return 0;
    close $fh;
    return 1;
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Script>

=item L<Essentials::Script::Heartbeat>

=back

=cut

1;
