package Essentials::Log::Writer;

use v5.26;
use strictures 2;
use utf8::all;

# VERSION

use Moo;
use IO::Handle;

use Essentials::Exception qw(throw);

# ABSTRACT: Writes formatted log lines to a destination

=head1 SYNOPSIS

  use Essentials::Log::Writer;

  my $writer = Essentials::Log::Writer->new;

  # write to STDERR
  $writer->write($formatted_line);

  # write to a file
  $writer->filename('/var/log/example.log');
  $writer->write($formatted_line);

=head1 DESCRIPTION

A module for writing formatted log lines to a destination,
such as STDERR or a file on disk.

=head1 ATTRIBUTES

=over

=item C<filename>

The file path to write to.

If this isn't provided, lines will be written to STDERR instead.

=cut

has filename => (
    is => 'ro',
);

=back

=cut

has _handle => (
    is      => 'lazy',
    default => sub {
        my $self = shift;

        if ($self->filename) {
            open my $handle, '>>', $self->filename
                or die 'Error opening ' . $self->filename . " for writing: $!";
            return $handle;
        }

        return *STDERR;
    },
);

=head1 METHODS

=over

=item C<write($line)>

Write the provided C<$line> to the active destination.

C<$line> should have already been formatted by something like L<Essentials::Log::Formatter>.

=cut

sub write {
    my ($self, $line) = @_;

    my $handle = $self->_handle;

    say $handle $line
        or throw "Error writing to log: $@";

    $handle->flush();
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Log>

=item L<Essentials::Log::Formatter>

=back

=cut

1;
