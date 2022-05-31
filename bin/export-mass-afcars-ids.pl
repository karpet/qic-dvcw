#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Text::CSV_XS qw( csv );
use Data::Dump qw( dump );
use DBI;

my $afcars_file = "$FindBin::Bin/../eval/afcars.db";
my $afcars_dbh  = DBI->connect( "dbi:SQLite:dbname=$afcars_file",
    "", "", { RaiseError => 1, } );

my $afcars_sth = $afcars_dbh->prepare("select c.id, e.extras from episodes as e inner join children as c on e.child_id=c.id where c.State = '25'");
$afcars_sth->execute();
print "state,rec_number,person_id,case_id\n";
my %ids;
while ( my $afcars = $afcars_sth->fetchrow_hashref() ) {
    # dump $afcars;
    my ($state, $rec_number) = split("-", $afcars->{id});
    $ids{$rec_number} ||= {};
    my $e = JSON::decode_json($afcars->{extras});
    my $person_id = $e->{"QIC Person ID"};
    my $case_id = $e->{"QIC Case ID"};
    $ids{$rec_number}->{person_id} ||= $person_id;
    $ids{$rec_number}->{case_id} ||= $case_id;
}

for my $rec_number (sort keys %ids) {
    my $person_id = $ids{$rec_number}->{person_id};
    my $case_id = $ids{$rec_number}->{case_id};
    printf("25,%s,%s,%s\n", $rec_number, $person_id, $case_id);
}
