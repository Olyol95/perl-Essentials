package Essentials::Exception;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use Carp qw(longmess);

use Exporter qw(import);

with 'Throwable';

our @EXPORT_OK = qw(throw);

# ABSTRACT: A throwable exception object with a stack trace.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module extends L<Throwable> to provide a convenient exception
containing both a message and a stack trace.

=cut

use overload fallback => 1,
    '""' => sub { shift->message };

=head1 METHODS

=over

=item C<message>

Returns a description of the exception that has been thrown.

=cut

has message => (
    is       => 'ro',
    required => 1,
);

=item C<stack_trace>

Returns a string containing the state of the call stack at the
point that the exception was thrown.

=cut

has stack_trace => (
    is       => 'ro',
    required => 1,
);

=back

=head1 EXPORTED FUNCTIONS

=over

=item C<throw ($message)>

Dies with a new Essentials::Exception object containing the provided message.

=cut

sub throw {
    my $message = shift;

    $message //= 'Unknown';

    die Essentials::Exception->new_with_previous(
        message     => $message,
        stack_trace => longmess(),
    );
}

=back

=head1 SEE ALSO

=over

=item L<Throwable>

=back

=cut

1;
