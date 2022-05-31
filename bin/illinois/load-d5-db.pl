#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Text::CSV_XS qw( csv );
use Data::Dump qw( dump );
use DBIx::InsertHash;
use DBI;
use Term::ProgressBar;

my $ncands_ids = csv(
    in      => "$FindBin::Bin/../../eval/ill-ncands-ids.csv",
    headers => "auto"
);

my $afcars_ids = csv(
    in      => "$FindBin::Bin/../../eval/ill-afcars-ids.csv",
    headers => "auto"
);

# hashify by the QIC person ID
my %afcars_lookup = map { $_->{rec_number} => $_ } @$afcars_ids;
my %ncands_lookup = map { $_->{ncands_id}  => $_ } @$ncands_ids;

my $dbfile = "$FindBin::Bin/../../eval/datasets.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, AutoCommit => 1, } );
my $ds5 = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'ds5',
);

my %missing;

sub get_afcars_id {
    my $rec = shift;
    if ( !exists $ncands_lookup{ $rec->{child_state_id} } ) {

        # warn "no AFCARS ID for QIC Person ID " . $rec->{child_state_id};
        $missing{afcars}++;
        return;
    }
    return $ncands_lookup{ $rec->{child_state_id} }->{afcars_id};
}

sub get_ncands_id {
    my $rec = shift;
    if ( !exists $ncands_lookup{ $rec->{child_state_id} } ) {

        # warn "no NCANDS ID for QIC Person ID " . $rec->{child_state_id};
        $missing{ncands}++;
        return;
    }
    my $ncands_id = $ncands_lookup{ $rec->{child_state_id} }->{ncands_id};
    my $afcars_id = $ncands_lookup{ $rec->{child_state_id} }->{afcars_id};
    if ( $rec->{afcars_id} and $afcars_id ne $rec->{afcars_id} ) {
        die
            "Found NCANDS ID but associated AFCARS ID $afcars_id does not match: "
            . dump($rec);
    }
    return $ncands_id;
}

for my $csv_file (@ARGV) {
    print "Loading: $csv_file\n";
    my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
    open my $fh, "<", $csv_file;
    my @headers = $csv->header($fh);

    my $rows = csv( in => $csv_file, headers => "auto" );

    printf( "Found %s rows\n", scalar(@$rows) );
    my $progress = Term::ProgressBar->new(
        { count => scalar(@$rows), ETA => 'linear', } );

    $dbh->begin_work;

    for my $row (@$rows) {
        my $rec = {
            in_person_visits => $row->{in_person_visits},
            video_visits     => $row->{video_visits},
            month            => $row->{month},
            child_state_id   => $row->{NCANDS_id},
            case_id          => $row->{SACWIS_case_id},
            state            => "IL"
        };
        $rec->{afcars_id} = get_afcars_id($rec);
        $rec->{ncands_id} = get_ncands_id($rec);
        $ds5->insert($rec);
        $progress->update();
    }

    # $progress->update(scalar(@$rows));

    $dbh->commit;
}

print "Missing crosswalk IDs:\n";
dump \%missing;

