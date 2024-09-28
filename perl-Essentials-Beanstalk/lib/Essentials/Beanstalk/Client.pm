package Essentials::Beanstalk::Client;

use v5.26;
use strictures 2;

# VERSION

use Moo;

use Essentials::Beanstalk::Priority qw($MEDIUM);
use Essentials::Exception qw(throw);

extends 'Beanstalk::Client';

# ABSTRACT: A simple wrapper around Beanstalk::Client with priority enums and exceptions

=head1 SYNOPSIS

  use Try::Tiny;
  use Essentials::Beanstalk::Client;
  use Essentials::Beanstalk::Priority qw($LOW);

  my $client = Essentials::Beanstalk::Client->new;

  # reserve a job
  try {
      my $job = $client->reserve(2);

      if ($job) {
          # do some work...
          foo($job);
          $job->delete;
      }
      # timeouts are not treated as fatal
      elsif ($client->error eq 'TIMED_OUT') {
          warn "timed out reserving job";
      }
  }
  catch {
      # $client->error may raise an Essentials::Exception
      warn $_->message;
      warn $_->stack_trace;
  };

  # add a job at the default priority
  $client->put($args, $data);

  # add a job at low priority
  $client->put({ priority => $LOW }, $data);

=head1 DESCRIPTION

This module provides a simple wrapper around L<Beanstalk::Client>, adding support
for priority values as enums via L<Essentials::Beanstalk::Priority>, and wrapping
fatal exceptions returned via the C<error> method as instances of L<Essentials::Exception>.

=head1 METHODS

See L<Beanstalk::Client> for the full documentation on all inherited methods.

=over

=item C<new(%args)>

See L<Beanstalk::Client#new>.

Defaults the C<priority> attribute to the medium L<Essentials::Beanstalk::Priority>.

=cut

sub FOREIGNBUILDARGS {
    my ($class, %args) = @_;

    return {
        priority => $MEDIUM,
        %args,
    };
}

=item C<error>

See L<Beanstalk::Client#error>.

Returns the last error that was encountered.

Timeouts and interrupts from system calls are treated as non-fatal.

Any other errors will raise an L<Essentials::Exception>.

This allows you to handle timeouts more gracefully within a C<try> block.

=cut

around error => sub {
    my $orig = shift;
    my $self = shift;

    my $error = $self->$orig(@_);

    return unless $error;

    if ($error eq 'TIMED_OUT') {
        return $error;
    }
    if ($error eq 'Interrupted system call') {
        return $error;
    }

    throw "Beanstalk client encountered an error: $error";
};

=back

=head1 SEE ALSO

=over

=item L<Beanstalk::Client>

=item L<Essentials::Beanstalk::Consumer>

=item L<Essentials::Beanstalk::Producer>

=item L<Essentials::Beanstalk::Priority>

=back

=cut

1;
