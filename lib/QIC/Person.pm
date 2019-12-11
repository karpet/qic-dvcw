package QIC::Person;
use strict;
use base qw( QIC::Record );

our $DOB_DELIM = "\003";   # coerce Excel into not autoformatting dates in CSV

sub dob_safe {
    my $self = shift;
    return ( $self->dob || "" ) . $DOB_DELIM;
}

sub unique_id {
    my $self = shift;
    ( my $first = $self->first_name_only ) =~ s/\W//g;
    ( my $last  = $self->last_name ) =~ s/\W//g;
    my $first_initial  = ( split( '',  $first ) )[0];
    my $second_initial = ( split( '',  $first ) )[1];
    my $last_initial   = ( split( '',  $last ) )[0];
    my $year           = $self->dob ? $self->dob->year : '';
    return
        lc(
        join( '-', $first_initial, $second_initial, $last_initial, $year ) );
}

sub first_name_only {
    my $self = shift;
    my $n    = $self->first_name;
    $n =~ s/\ \w\.?$//;
    return $n;
}

sub preferred_phone {
    my $self = shift;
    return
           $self->mobile_phone
        || $self->home_phone
        || $self->work_phone;
}

sub age {
    my $self = shift;
    return 0 unless $self->dob;
    my ($year) = ( $self->dob =~ m/^(\d+)-/ );
    return 2019 - $year;
}

1;