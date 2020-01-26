package QIC::Case;
use strict;
use base qw( QIC::Record );
use List::Util qw(shuffle);
use Data::Dump qw( dump );

__PACKAGE__->meta->setup(
    table => 'cases',

    columns => [
        id             => { type => 'varchar', length => 16 },
        case_worker_id => { type => 'varchar', length => 16 },
        survey_name    => { type => 'varchar', length => 16 },
        closed_at      => { type => 'datetime' },
        replaced_at    => { type => 'datetime' },
        surveyed_at    => { type => 'datetime' },
        created_at     => { type => 'datetime' },
        updated_at     => { type => 'datetime' },

    ],

    primary_key_columns => ['id'],

    foreign_keys => [
        case_worker => {
            class       => 'QIC::CaseWorker',
            key_columns => { case_worker_id => 'id' }
        }
    ],

    relationships => [
        adults => {
            class      => 'QIC::Adult',
            column_map => { id => 'case_id' },
            type       => 'one to many',
        },
        children => {
            class      => 'QIC::Child',
            column_map => { id => 'case_id' },
            type       => 'one to many',
        },
    ],
);

sub worker_name {
    my $self = shift;
    return sprintf( "%s %s",
        $self->case_worker->first_name,
        $self->case_worker->last_name );
}

sub potential_focal_children {
    my $self = shift;
    return [ grep { $_->age < 11 } @{ $self->children_sorted } ];
}

sub focal_child {
    my $self            = shift;
    my $pfc             = $self->potential_focal_children;
    my @between_5_and_9 = grep { $_->age >= 5 && $_->age <= 9 } @$pfc;
    my @tenyo           = grep { $_->age == 10 } @$pfc;
    my @under5          = grep { $_->age < 5 } @$pfc;

    #warn dump( \@between_5_and_9 );
    #warn dump( \@tenyo );
    #warn dump( \@under5 );
    #warn dump($pfc);

    return
           shuffle(@between_5_and_9)
        || shuffle(@tenyo)
        || shuffle(@under5)
        || shuffle(@$pfc);
}

sub as_csv_row {
    my $self = shift;

    my $focal_child = $self->focal_child;

    my $row = {
        case_id                => $self->id,
        site_name              => $self->case_worker->site_name,
        site_office_name       => $self->case_worker->site_office_name,
        survey_number          => $self->survey_name,
        case_worker_id         => $self->case_worker_id,
        case_worker_first_name => $self->case_worker->first_name,
        case_worker_last_name  => $self->case_worker->last_name,
        email                  => $self->case_worker->email,
        focal_child_id         => $focal_child->client_id,
        focal_child_first_name => $focal_child->first_name,
        focal_child_last_name  => $focal_child->last_name,
        focal_child_dob        => $focal_child->dob_safe,
    };

    my $pfc = $self->potential_focal_children;
    my $i   = 0;
    for my $child (@$pfc) {
        $i++;
        $row->{"child_${i}_id"}         = $child->client_id;
        $row->{"child_${i}_first_name"} = $child->first_name;
        $row->{"child_${i}_last_name"}  = $child->last_name;
        $row->{"child_${i}_dob"}        = $child->dob_safe;
    }

    $i = 0;
    for my $adult ( @{ $self->adults_sorted } ) {
        $i++;
        $row->{"adult_${i}_id"}         = $adult->client_id;
        $row->{"adult_${i}_first_name"} = $adult->first_name;
        $row->{"adult_${i}_last_name"}  = $adult->last_name;
        $row->{"adult_${i}_dob"}        = $adult->dob_safe;
        $row->{"adult_${i}_street_one"} = $adult->address_one;
        $row->{"adult_${i}_street_two"} = $adult->address_two;
        $row->{"adult_${i}_city"}       = $adult->city;
        $row->{"adult_${i}_state"}      = $adult->state;
        $row->{"adult_${i}_zipcode"}    = $adult->zipcode;
        $row->{"adult_${i}_phone"}      = $adult->preferred_phone;
        $row->{"adult_${i}_email"}      = $adult->email;
        $row->{"adult_${i}_role"}       = $adult->role;
    }

    # clean data
    for my $k (keys %$row) {
        $row->{$k} =~ s/^unknown$//i;
    }

    return $row;
}

sub adults_sorted {
    my $self    = shift;
    my @mothers = grep { $_->role eq 'Mother' } @{ $self->adults };
    my @fathers = grep { $_->role eq 'Father' } @{ $self->adults };
    my @adults  = grep { $_->role eq 'Adult' } @{ $self->adults };

    # id is not unique (alas) so we must de-dupe based on name and dob
    my %seen;
    my @sorted_uniq
        = grep { !$seen{ $_->unique_id }++ } ( @mothers, @adults, @fathers );

    # some names are "unknown" (case sensitive)
    return [ grep { $_->unique_id !~ /unknown/ } @sorted_uniq ];
}

sub children_sorted {
    my $self = shift;
    my %seen;
    my @sorted_uniq
        = grep { !$seen{ $_->unique_id }++ } @{ $self->children };
    return [ grep { $_->unique_id !~ /unknown/ } @sorted_uniq ];
}

sub eligible {
    my $self = shift;
    return 0 if $self->closed_at;

    return 0 unless $self->focal_child;

    #warn "case has focal child";
    return 0 unless scalar( @{ $self->adults_sorted } ) > 0;

    #warn "case has adults";
    return 0 if $self->surveyed_at;

    #warn "case not yet surveyed";
    return 1;
}

sub surveyed_cases {
    my $self = shift;
    return $self->case_worker->find_cases(
        query => [
            '!surveyed_at' => undef,
            'replaced_at'  => undef,
            '!id'          => $self->id
        ]
    );
}

# sequential number of the case per case_worker, over all surveys.
sub next_survey_name {
    my $self             = shift;
    my $already_surveyed = $self->surveyed_cases;
    return scalar(@$already_surveyed) + 1;
}

1;
