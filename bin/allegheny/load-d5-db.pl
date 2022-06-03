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

my $dbfile = "$FindBin::Bin/../../eval/datasets.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, AutoCommit => 1, } );
my $ds5 = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'ds5',
);

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
        my $rec = { %$row, state => "PA" };
        $ds5->insert($rec);
        $progress->update();
    }

    # $progress->update(scarla(@$rows));

    $dbh->commit;
}

