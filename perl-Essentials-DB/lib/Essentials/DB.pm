package Essentials::DB;

use v5.26;
use strictures 2;

# VERSION

use Moo;
use Moo::Role ();

# ABSTRACT: Modules for managing multiple DBIx::Class schemas under custom namespaces

=head1 SYNOPSIS

Given the following SQL schema:

  CREATE TABLE `group` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `description` VARCHAR(255) DEFAULT '',
    PRIMARY KEY (`id`)
  ) DEFAULT CHARSET=utf8mb4;

  CREATE TABLE `user` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL,
    `email` VARCHAR(64) NOT NULL UNIQUE,
    `password_hash` CHAR(60) NOT NULL,
    PRIMARY KEY (`id`)
  ) DEFAULT CHARSET=utf8mb4;

  CREATE TABLE `user_group` (
    `user_id` INT UNSIGNED NOT NULL,
    `group_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`user_id`, `group_id`),
    FOREIGN KEY (`user_id`)
      REFERENCES `user`(`id`)
      ON DELETE CASCADE,
    FOREIGN KEY (`group_id`)
      REFERENCES `group`(`id`)
      ON DELETE CASCADE
  ) DEFAULT CHARSET=utf8mb4;

Create some corresponding L<DBIx::Class::ResultSource> classes (or generate them using L<dbicdump>)...

I<MyApp/DB/Result/Group.pm>

  package MyApp::DB::Result::Group;

  use base 'DBIx::Class::Core';

  __PACKAGE__->table('group');
  __PACKAGE__->add_columns(
    id   => {
      data_type         => 'integer',
      extra             => { unsigned => 1 },
      is_auto_increment => 1,
      is_nullable       => 0,
    },
    name => {
      data_type   => 'varchar',
      size        => 64,
      is_nullable => 0,
    },
    description => {
      data_type     => 'varchar',
      size          => 255,
      is_nullable   => 1,
      default_value => '',
    },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(
    'user_groups',
    'MyApp::DB::Result::UserGroup',
    {
      'foreign.group_id' => 'self.id',
    },
    {
      cascade_copy => 0,
      cascade_delete => 0,
    }
  );
  __PACKAGE__->many_to_many('users', 'user_groups', 'user');

  1;

I<MyApp/DB/Result/User.pm>

  package MyApp::DB::Result::User;

  use base 'DBIx::Class::Core';

  __PACKAGE__->table('user');
  __PACKAGE__->add_columns(
    id   => {
      data_type         => 'integer',
      extra             => { unsigned => 1 },
      is_auto_increment => 1,
      is_nullable       => 0,
    },
    name => {
      data_type   => 'varchar',
      size        => 64,
      is_nullable => 0,
    },
    email => {
      data_type   => 'varchar',
      size        => 64,
      is_nullable => 0,
    },
    password_hash => {
      data_type   => 'char',
      size        => 60,
      is_nullable => 0,
    },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint('email', ['email']);
  __PACKAGE__->has_many(
    'user_groups',
    'MyApp::DB::Result::UserGroup',
    {
      'foreign.user_id' => 'self.id',
    },
    {
      cascade_copy => 0,
      cascade_delete => 0,
    }
  );
  __PACKAGE__->many_to_many("groups", "user_groups", "group");

  1;

I<MyApp/DB/Result/UserGroup.pm>

  package MyApp::DB::Result::UserGroup;

  use base 'DBIx::Class::Core';

  __PACKAGE__->table('user_group');
  __PACKAGE__->add_columns(
    user_id   => {
      data_type      => 'integer',
      extra          => { unsigned => 1 },
      is_foreign_key => 1,
      is_nullable    => 0,
    },
    group_id   => {
      data_type      => 'integer',
      extra          => { unsigned => 1 },
      is_foreign_key => 1,
      is_nullable    => 0,
    },
  );
  __PACKAGE__->set_primary_key('user_id', 'group_id');
  __PACKAGE__->belongs_to(
    'group',
    'MyApp::DB::Result::Group',
    {
      id => 'group_id',
    },
    {
      is_deferrable => 1,
      on_delete => 'CASCADE',
      on_update => 'RESTRICT',
    },
  );
  __PACKAGE__->belongs_to(
    'user',
    'MyApp::DB::Result::User',
    {
      id => 'user_id',
    },
    {
      is_deferrable => 1,
      on_delete => 'CASCADE',
      on_update => 'RESTRICT',
    },
  );

  1;

Now you can use this schema to interact with the database via L<Essentials::DB>.

In I<MyApp.pm>:

  package MyApp;

  use Essentials::DB;
  use Essentials::DB::Connection::Config;

  # Load a subclass of DBIx::Class::Schema under MyApp::DB,
  # or create one if it doesn't exist
  my $db = Essentials::DB->new(package => 'MyApp::DB');

  # Load your schema information
  $db->package->load_namespaces(...);

  # create a new connection
  my $conn = $db->connect(
      Essentials::DB::Connection::Config->new(
          driver   => 'mysql', # DBI driver name
          database => 'mydb',
          hostname => 'writer.mydb.com',
          username => 'example_rw',
          password => 'hunter2',
      )
  );

  # fetch all users
  my $all_users = $conn->resultset('User');
  # read the next row
  my $next_user = $all_users->next;
  # or slurp all rows into an array
  my @all_users = $all_users->all;

  # find a particular group
  my $group = $conn->resultset('Group')->find(
      { name => 'Admin' }
  );

  # find all users in that group
  my $admins = $group->users;

  # or do it all at once with a join
  $admins = $conn->resultset('User')->search(
      { 'group.name' => 'Admin' },
      { join => 'groups' },
  );

  # create a new user and add them to a group in a transaction
  # throws an Essentials::Exception and rolls back on error
  $conn->txn(sub {
      # $conn is passed in as the first argument
      my $c = shift;
      my $new_user = $c->resultset('User')->create({
          name          => 'Alice Johnson',
          email         => 'alice.johnson@example.com',
          password_hash => '$2b$12$securehashedpassword...',
      });
      $new_user->add_to_groups({ name => 'Member' });
  });

  my $pid = fork();

  # this is no longer safe!
  # take a look at Essentials::DB::Pool for a thread-safe alternative
  $conn->resultset(...);

  1;

See L<DBIx::Class> for comprehensive documentation on the functionality
of the connections.

=head1 DESCRIPTION

This module provides convenient methods for managing and connecting to
multiple L<DBIx::Class> schemas within the same project.

=head1 ATTRIBUTES

=head3 package

The name of the L<DBIx::Class::Schema> module to use for connections to
the database.

If this doesn't exist, one will be created for you.

This allows you to conveniently define multiple schemas within the
same application without needing to maintain the implementation of
each subclass yourself.

=cut

has package => (
    is       => 'ro',
    required => 1,
);

sub BUILD {
    my $self = shift;

    my $db_name = $self->package;

    unless ($db_name->can('connect')) {
        my $class = Moo::Role->create_class_with_roles(
            'DBIx::Class::Schema',
            'Essentials::DB::Connection'
        );
        ## no critic
        no strict 'refs';
        @{"${db_name}::ISA"} = ($class);
        ## use critic
    }
}

=head1 METHODS

=head3 C<new(%args)>

Creates and returns a new instance of L<Essentials::DB>.

The L<DBIx::Class::Schema> package provided by the C<package> attribute is loaded and
used for connections created by this instance. If the package doesn't exist, one is
created for you.

Before you can connect to the database, you will need to load your result and resultset
definitions using the static methods provided by L<DBIx::Class::Schema>, such as 
L<DBIx::Class::Schema#load_namespaces>. These can be accessed via the C<package> attribute:

  # creates the 'My::DB' module for you if it doesn't exist
  my $db = Essentials::DB->new(package => 'My::DB');

  # call a static method on 'My::DB' via its name
  $db->package->load_namespaces(...);

=cut

=head3 C<connect($config, $attr)>

Connects to the database via the config provided, and returns a
new instance of L<Essentials::DB::Connection> under your custom namespace.

C<$config> is an instance of L<Essentials::DB::Connection::Config>.

  my $conn = $schema->connect(
      Essentials::DB::Connection::Config->new(...),
  );

C<$attr> is an optional hashref containing overrides for the L<DBI> connection
attributes, such as C<AutoCommit> and C<RaiseError>.

See L<DBIx::Class::Schema> for comprehensive documentation on the functionality
of the connections.

=cut

sub connect {
    my ($self, $config, $attr) = @_;

    return $self->package->connect(
        $config->dsn,
        $config->username,
        $config->password,
        $attr,
    );
}

=head1 SEE ALSO

=over

=item L<DBIx::Class>

=item L<Essentials::DB::Pool>

=item L<Essentials::DB::Connection>

=back

=cut

1;
