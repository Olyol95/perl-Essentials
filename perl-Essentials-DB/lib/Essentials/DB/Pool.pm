package Essentials::DB::Pool;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use Types::Standard qw(HashRef InstanceOf);

use Essentials::Exception qw(throw);

extends 'Essentials::DB';

# ABSTRACT: Thread-safe management of multiple connections to a DBIx::Class schema

=head1 SYNOPSIS

  use Essentials::DB::Pool;
  use Essentials::DB::Connection::Config;

  # create a pool of re-usable connections via a custom DBIx::Class schema
  my $db = Essentials::DB::Pool->new(
      package => 'MyApp::DB',
      config  => {
          readwrite => Essentials::DB::Connection::Config->new(
              driver   => 'mysql', # DBI driver name
              database => 'mydb',
              hostname => 'writer.mydb.com',
              username => 'example_rw',
              password => 'hunter2',
          ),
          readonly  => Essentials::DB::Connection::Config->new(
              driver   => 'mysql', # DBI driver name
              database => 'mydb',
              hostname => 'reader.mydb.com',
              username => 'example_ro',
              password => 'changeme',
          ),
      }
  );

  # Load your schema information
  $db->package->load_namespaces(...);

  # get a read-only handle from the pool
  my $ro = $db->connect('readonly');

  # fetch all users
  my $all_users = $ro->resultset('User');
  # read the next row
  my $next_user = $ro->next;
  # or slurp all rows into an array
  my @all_users = $ro->all;

  # find a particular group
  my $group = $ro->resultset('Group')->find(
      { name => 'Admin' }
  );

  # find all users in that group
  my $admins = $group->users;

  # or do it all at once with a join
  $admins = $ro->resultset('User')->search(
      { 'group.name' => 'Admin' },
      { join => 'groups' },
  );

  # get a read-write connection from the pool
  my $rw = $db->connect('readwrite');

  # create a new user and add them to a group in a transaction
  # throws an Essentials::Exception and rolls back on error
  $rw->txn(sub {
      # $rw is passed in as the first argument
      my $c = shift;
      my $new_user = $c->resultset('User')->create({
          name          => 'Alice Johnson',
          email         => 'alice.johnson@example.com',
          password_hash => '$2b$12$securehashedpassword...',
      });
      $new_user->add_to_groups({ name => 'Member' });
  });

  # fetching a handle again in the same thread re-uses
  # the existing connection
  sub example {
      my $cached = $db->connect('readonly');
      ...
  }

  my $pid = fork();

  # this is still safe, and will return a new connection
  $db->connect('readwrite')->resultset(...);

  # you can obtain the underlying DBI handle if needed
  $db->connect(...)->storage->dbh;

See L<DBIx::Class> for comprehensive documentation on the functionality
of the connections.

=head1 DESCRIPTION

This module provides a thread-safe mechanism for managing multiple
handles (e.g. read-only, read-write) to the same database via
L<DBIx::Class> under custom namespaces.

Returns a new instance of L<Essentials::DB::Pool> configured
with the connection details provided.

L<Essentials::DB::Pool> provides a thread-safe mechanism for
managing multiple handles (e.g. read-only, read-write) to the
same database.

=head1 ATTRIBUTES

See L<Essentials::DB#ATTRIBUTES> for a list of inherited attributes.

=head3 C<config>

A hash reference that maps handle names to an instance of
L<Essentials::DB::Connection::Config>, which will be used to
instantiate a new connection for that handle.

=cut

has config => (
    is      => 'ro',
    default => sub { {} },
    isa     => HashRef[InstanceOf['Essentials::DB::Connection::Config']],
);

has _conns => (
    is      => 'ro',
    default => sub { {} },
);

=head1 METHODS

See L<Essentials::DB#METHODS> for a list of inherited methods.

=head3 C<connect($identifier, $attr)>

Connects to the database and returns an instance of L<Essentials::DB::Connection>.

The C<$identifier> provided is matched against the contents of the C<config>
attribute to determine which connection to instantiate.

If a connection is already open for the current thread, it will be returned,
otherwise a new connection will be established.

C<$attr> is an optional hashref containing overrides for the L<DBI> connection
attributes, such as C<AutoCommit> and C<RaiseError>.

=cut

sub connect {
    my ($self, $identifier, $attr) = @_;

    my $thread = $self->_thread_id;
    my $conn   = $self->_conns->{$identifier}->{$thread};

    unless ($conn && $conn->storage->connected) {
        my $config = $self->config->{$identifier};
        throw "No config found for $identifier" unless $config;
        $conn = $self->SUPER::connect($config, $attr);
        $self->_conns->{$identifier}->{$thread} = $conn;
    }

    return $conn;
}

sub _thread_id {
    return $$;
}

=head1 SEE ALSO

=over

=item L<DBIx::Class>

=item L<Essentials::DB>

=item L<Essentials::DB::Connection>

=back

=cut

1;
