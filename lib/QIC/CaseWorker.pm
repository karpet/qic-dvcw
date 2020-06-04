package QIC::CaseWorker;
use strict;
use base qw( QIC::Record );
use List::Util qw(shuffle);

__PACKAGE__->meta->setup(
    table => 'case_workers',

    columns => [
        id               => { type => 'varchar', length => 16 },
        first_name       => { type => 'varchar', length => 255 },
        last_name        => { type => 'varchar', length => 255 },
        email            => { type => 'varchar', length => 255 },
        site_name        => { type => 'varchar', length => 255 },
        site_office_name => { type => 'varchar', length => 255 },
        created_at       => { type => 'datetime' },
        updated_at       => { type => 'datetime' },

    ],

    primary_key_columns => ['id'],

    relationships => [
        cases => {
            class      => 'QIC::Case',
            column_map => { id => 'case_worker_id' },
            type       => 'one to many',
        },
    ],
);

sub for_site_name {
    my $class = shift;
    return $class->fetch_all( query => [ site_name => shift ] );
}

sub number_of_surveys {
    my $self = shift;

    return
          scalar( @{ $self->surveyed_cases } )
        - scalar( @{ $self->replaced_cases } );
}

sub surveyed_cases {
    my $self = shift;
    return $self->find_cases( query => [ '!surveyed_at' => undef, ] );
}

sub replaced_cases {
    my $self = shift;
    return $self->find_cases( query => [ '!replaced_at' => undef, ] );
}

sub closed_cases {
    my $self = shift;
    return $self->find_cases( query => [ '!closed_at' => undef, ] );
}

sub number_of_surveyed_cases {
    my $self = shift;
    return scalar( @{ $self->surveyed_cases } );
}

sub number_of_replaced_cases {
    my $self = shift;
    return scalar( @{ $self->replaced_cases } );
}

sub number_of_closed_cases {
    my $self = shift;
    return scalar( @{ $self->closed_cases } );
}

sub eligible_cases {
    my $self = shift;
    return [
        sort { $a->id cmp $b->id }
        grep { $_->eligible } @{ $self->cases }
    ];
}

sub random_cases {
    my $self = shift;
    my $count = shift || 3;

    my @shuffled = shuffle( @{ $self->eligible_cases } );
    if ( scalar(@shuffled) <= $count ) {
        return [@shuffled];
    }

    return [ @shuffled[ 0 .. ( $count - 1 ) ] ];
}

1;
