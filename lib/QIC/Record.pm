package QIC::Record;
use strict;
use base qw(
    Rose::DB::Object
    Rose::DB::Object::Helpers
    Rose::DBx::Object::MoreHelpers
);
use Carp;
use QIC::DB;

sub init_db {
    QIC::DB->new_or_cached();
}

sub apply_defaults {
    my $self   = shift;
    my $is_new = shift;
    my $now    = DateTime->now();

    for my $column ( $self->meta->columns ) {
        my $name       = $column->name;
        my $set_method = $column->mutator_method_name;

        if ( $is_new && $name eq 'created_at' ) {
            $self->$set_method($now);
        }
        if ( $name eq 'updated_at' ) {
            $self->$set_method($now);
        }
    }

    return $self;
}

sub insert {
    my $self = shift;
    $self->apply_defaults(1);
    return $self->SUPER::insert(@_);
}

sub update {
    my $self = shift;
    my %arg  = @_;
    $arg{changes_only} = 1;
    $self->apply_defaults;
    $self->SUPER::update(%arg);
}

1;
