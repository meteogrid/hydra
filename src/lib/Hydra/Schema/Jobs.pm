use utf8;
package Hydra::Schema::Jobs;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Hydra::Schema::Jobs

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components("Helper::Row::ToJSON");

=head1 TABLE: C<Jobs>

=cut

__PACKAGE__->table("Jobs");

=head1 ACCESSORS

=head2 project

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0
  is_serializable: 1

=head2 jobset

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0
  is_serializable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0
  is_serializable: 1

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 errormsg

  data_type: 'text'
  is_nullable: 1
  is_serializable: 1

=head2 firstevaltime

  data_type: 'integer'
  is_nullable: 1

=head2 lastevaltime

  data_type: 'integer'
  is_nullable: 1

=head2 disabled

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "project",
  {
    data_type       => "text",
    is_foreign_key  => 1,
    is_nullable     => 0,
    is_serializable => 1,
  },
  "jobset",
  {
    data_type       => "text",
    is_foreign_key  => 1,
    is_nullable     => 0,
    is_serializable => 1,
  },
  "name",
  { data_type => "text", is_nullable => 0, is_serializable => 1 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "errormsg",
  { data_type => "text", is_nullable => 1, is_serializable => 1 },
  "firstevaltime",
  { data_type => "integer", is_nullable => 1 },
  "lastevaltime",
  { data_type => "integer", is_nullable => 1 },
  "disabled",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project>

=item * L</jobset>

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("project", "jobset", "name");

=head1 RELATIONS

=head2 builds

Type: has_many

Related object: L<Hydra::Schema::Builds>

=cut

__PACKAGE__->has_many(
  "builds",
  "Hydra::Schema::Builds",
  {
    "foreign.job"     => "self.name",
    "foreign.jobset"  => "self.jobset",
    "foreign.project" => "self.project",
  },
  undef,
);

=head2 jobset

Type: belongs_to

Related object: L<Hydra::Schema::Jobsets>

=cut

__PACKAGE__->belongs_to(
  "jobset",
  "Hydra::Schema::Jobsets",
  { name => "jobset", project => "project" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 project

Type: belongs_to

Related object: L<Hydra::Schema::Projects>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Hydra::Schema::Projects",
  { name => "project" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-27 16:37:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/LMRYf6JlzTrl51hAd6bfw

1;
