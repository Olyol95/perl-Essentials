package Essentials::Beanstalk::Producer;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;

use Essentials::Exception qw(throw);

# ABSTRACT: Moo::Role for adding jobs to beanstalk tubes

=head1 SYNOPSIS

In C<My/Producer.pm>

  package My::Producer;

  use Moo;

  with 'Essentials::Beanstalk::Producer';

  # define a method for adding a specific type of job
  sub process_new_foo {
      my ($self, $foo_id) = @_;

      return $self->add_job(process_new_foo => {
          foo_id         => $foo_id,
          other_job_data => 'example',
      });
  }

  1;

In C<my-script.pl>

  #!/usr/bin/env perl

  use Try::Tiny;

  use My::Producer;

  my $producer = My::Producer->new;

  # add a new job
  try {
      my $job = $producer->process_new_foo(1234);
  }
  catch {
      warn $_;
  };

=head1 DESCRIPTION

This package provides a L<Moo::Role> that can be used to emit jobs
onto multiple beanstalk tubes in an extensible way.

=head1 ATTRIBUTES

=over

=item C<client>

An instance of L<Essentials::Beanstalk::Client>.

=cut

has client => (
    is      => 'ro',
    default => sub {
        Essentials::Beanstalk::Client->new,
    },
);

=back

=head1 METHODS

=over

=item C<add_job($tube, $data, $args)>

Adds a job to the specified tube.

Returns an instance of L<Beanstalk::Job> if successful, otherwise
an L<Essentials::Exception> will be thrown.

C<$tube> is a string containing the name of the tube to add the job to.

C<$data> is a hashref containing the job data.

C<$args> is a hashref of optional arguments.

=over

=item priority

The priority of the new job.

Jobs with smaller priority values are scheduled first.

See L<Essentials::Beanstalk::Priority>.

=item delay

Integer number of seconds before the job may be picked up by a consumer.

Defaults to 0.

=item ttr

Integer number of seconds that a consumer may reserve the job for before
it is released back to the queue.

The minimum value is 1.

Defaults to 60.

=back

=cut

sub add_job {
    my ($self, $tube, $data, $args) = @_;

    throw "No tube provided" unless $tube;
    throw "No job data provided" unless $data;

    throw "Job data must be a hashref" unless ref $data eq 'HASH';

    $args //= {};

    $self->client->use($tube);
    my $job = $self->client->put(
        {
            delay => 0,
            ttr   => 60,
            %$args
        },
        $data,
    );

    return $job if $job;

    throw "Error queueing job: " . $self->client->error;
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Beanstalk::Client>

=item L<Essentials::Beanstalk::Producer>

=back

=cut

1;
