#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Text::CSV_XS qw( csv );
use Data::Dump qw( dump );
use DBI;

my $dbfile = "$FindBin::Bin/../eval/ncands.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, } );

my $sth
    = $dbh->prepare(
    "select c.AFCARSID, c.id, c.ChID, r.extras from children as c inner join reports as r on r.ChID=c.ChID where c.StaTerr = 'IL' and c.AFCARSID != '' "
    );
$sth->execute();
print "state,afcars_id,ncands_id,person_id,case_id\n";
my %ids;
while ( my $r = $sth->fetchrow_hashref() ) {
    my $child_id = $r->{ChID};
    next if $ids{$child_id}++;
    my $e         = JSON::decode_json( $r->{extras} );
    # print dump $e;
    my $person_id = $e->{chid_id_pers} || $e->{ID_INVST};
    $person_id = "" if $person_id eq "NULL";
    my $case_id = $e->{ID_CYCIS} || $e->{AFCARSID_cycis_case_id} || $e->{ID_INVST_CASE}; # used as AFCARS.RecNumbr
    if (!$case_id) {
        dump $r;
        dump $e;
    }
    $case_id = "" if $case_id eq "NULL";
    printf( "17,%s,%s,%s,%s\n",
        $r->{AFCARSID}, $child_id, $person_id, $case_id );
}
