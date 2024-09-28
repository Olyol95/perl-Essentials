package Essentials::Beanstalk::Consumer;

use v5.26;
use strictures 2;

# VERSION

use Moo::Role;
use Try::Tiny;

use Essentials::Exception qw(throw);

with 'Essentials::Script::Service';

# ABSTRACT: Moo::Role for a generic service worker that consumes jobs from a beanstalk tube

=head1 SYNOPSIS

In C<My/Consumer.pm>

  package My::Consumer;

  use Moo;
  
  with 'Essentials::Beanstalk::Consumer';

  # define the default tube to watch
  sub default_tube {
      return 'example_tube';
  }

  # handle incoming jobs
  sub process_job {
      my ($self, $job) = @_;

      # do some work...
      $self->foo(job->data);

      # delete the job
      $job->delete;
  }

  1;

In C<my-script.pl>

  #!/usr/bin/env perl

  use Essentials::Script::Heartbeat::Systemd;

  use My::Consumer;

  my $service = My::Consumer->new_with_opts(
      example_string => 'example-string=s',
      example_int    => 'baz=i',
      example_array  => 'array-item=s@',
      example_bool   => 'bool',
  )
  # Notify systemd when a job is processed
  ->with_heartbeat(
      Essentials::Script::Heartbeat::Systemd->new
  )
  # Wait at least 5 seconds between runs
  ->with_min_interval(5);

  # start the service (blocking)
  $service->start;

  # stop the service
  $service->stop;

  # check whether the service is running
  if ($service->running) { ... }

=head1 DESCRIPTION

This package provides a L<Moo::Role> for implementing robust service workers
that consume jobs from a beanstalk tube.

In addition to the functionality detailed below, this role provides all of
the benefits of L<Essentials::Script::Service>, including a convenient interface
for populating object attributes from command-line parameters as well as heartbeat
handlers for implementing service health checks.

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

=item C<reserve_timeout>

The number of seconds to block on when reserving a job.

Defaults to 3.

Note that setting a larger value may increase the time between
heartbeat measurements when the number of jobs is low.

=cut

has reserve_timeout => (
    is      => 'ro',
    default => 3,
);

=item C<retries>

The maximum number of times to retry a failing job before burying it.

For example, when set to C<2> an erroneous job will be processed up to
three times, and on the third time will be buried.

Defaults to 2.

=cut

has retries => (
    is      => 'ro',
    default => 2,
);

=item C<tube>

The name of the tube to consume jobs from.

The C<client> object will also use this tube for any created jobs unless
overridden manually.

The default value for this attribute must be implemented via the
C<default_tube> method.

=cut

has tube => (
    is      => 'ro',
    builder => 'default_tube',
);

=back

=head1 REQUIRED METHODS

The following methods require implementation in order to compose the role.

=over

=item C<default_tube>

Return the default name of the tube to consume jobs from.

Can be overridden via the C<tube> attribute.

=cut

requires 'default_tube';

=item C<process_job($self, $job)>

Process the provided L<Beanstalk::Job>.

Note that the job is not deleted automatically, you will need to handle
this yourself.

=cut

requires 'process_job';

=back

=head1 METHODS

=over

=item C<start>

Starts the service.

This call is blocking.

Jobs will be read from the configured tube and processed via L<process_job>.

Also see L<Essentials::Script::Service#start>.

=cut

sub start {
    my $self = shift;

    $self->log->info("Connecting to beanstalk", {
        server => $self->client->server,
        tube   => $self->tube,
    });
    $self->client->connect;

    $self->client->use($self->tube);
    $self->client->watch_only($self->tube);

    $self->SUPER::start();
}

=item C<run>

Runs a single iteration of the service.

It's unlikely that you will want to call this directly, instead see L<start>
to run the consumer as a service.

During this iteration, the service will:

=over

=item Attempt to read a job from the tube

=item Process the job via L<process_job>

=item If the job fails for some reason, it will be released unless C<retries> has
  been exceeded, in which case the job is buried

=back

=cut

sub run {
    my $self = shift;

    my $job;
    try {
        $job = $self->client->reserve(
            $self->reserve_timeout,
        );

        if ($job) {
            local $self->log->context->{bs_id} = $job->id;
            $self->process_job($job);
        }
        elsif ($self->client->error eq 'TIMED_OUT') {
            $self->log->debug("Timed out whilst reserving job", {
                timeout => $self->reserve_timeout,
            });
        }
    }
    catch {
        $self->log->error($_);
        if ($job) {
            my $attempts = $job->stats->reserves;
            if ($attempts > $self->retries) {
                $self->log->info("Retries exceeded, burying job", {
                    attempts => $attempts,
                    retries  => $self->retries,
                });
                $job->bury;
            }
            else {
                $self->log->debug("Retrying job", {
                    attempts => $attempts,
                    retries  => $self->retries,
                });
                $job->release;
            }
        }
    };
}

=back

=head1 SEE ALSO

=over

=item L<Essentials::Beanstalk::Client>

=item L<Essentials::Beanstalk::Producer>

=item L<Essentials::Script::Service>

=back

=cut

1;
