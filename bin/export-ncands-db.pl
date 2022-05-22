#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Text::CSV_XS qw( csv );
use Data::Dump qw( dump );
use DBI;

my $child_csv_file  = shift(@ARGV) || "children.csv";
my $report_csv_file = shift(@ARGV) || "reports.csv";

my $dbfile = "$FindBin::Bin/../eval/ncands.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, } );

my $reports_sth = $dbh->prepare(
    "select * from reports where ChID = ? order by RptDt asc");
my $children_sth = $dbh->prepare("select * from children");

$children_sth->execute();

my @dates = qw(
    RptDt
    InvDate
    RpDistDt
    ServDate
    RmvDate
    PetDate
    FCDchDt
);

my @CHILD_FIELDS = qw(
    DOB
    StaTerr
    ChID
    ChSex
    ChRacAI
    ChRacAs
    ChRacBl
    ChRacNH
    ChRacWh
    ChRacUd
    CEthn
    AFCARSID
);

my @REPORT_FIELDS = qw(
    SubYr
    StaTerr
    RptID
    RptFIPS
    RptDt
    RptTm
    InvDate
    InvStrTm
    RptSrc
    RptDisp
    RpDispDt
    Notifs
    PlnsFCr
    RefrCARA
    RU13
    IsIPSE
    ChID
    ChAge
    ChLvng
    ChMil
    ChPrior
    ChMal1
    Mal1Lev
    ChMal2
    Mal2Lev
    ChMal3
    Mal3Lev
    ChMal4
    Mal4Lev
    MalDeath
    CdAlc
    CdDrug
    CdRtrd
    CdEmotnl
    CdVisual
    CdLearn
    CdPhys
    CdBehav
    CdMedicl
    FCAlc
    FCDrug
    FCRtrd
    FCEmotnl
    FCVisual
    FCLearn
    FCPhys
    FCMedicl
    FCViol
    FCHouse
    FCMoney
    FCPublic
    PostServ
    ServDate
    FamSup
    FamPres
    FosterCr
    RmvDate
    JuvPet
    PetDate
    CoChRep
    Adopt
    CaseMang
    Counsel
    Daycare
    Educatn
    Employ
    FamPlan
    Health
    Homebase
    Housing
    TransLiv
    InfoRef
    Legal
    MentHlth
    PregPar
    Respite
    SSDisabl
    SSDelinq
    SubAbuse
    Transprt
    OtherSv
    FCDchDt
    Per1ID
    Per1Rel
    Per1Prnt
    Per1Cr
    Per1Age
    Per1Sex
    P1RacAI
    P1RacAs
    P1RacBl
    P1RacBH
    P1RacWh
    P1RacUD
    Per1Ethn
    Per1Mil
    Per1Pior
    Per1Mal1
    Per1Mal2
    Per1Mal3
    Per1Mal4
    Per2ID
    Per2Rel
    Per2Prnt
    Per2Cr
    Per2Age
    Per2Sex
    P2RacAI
    P2RacAs
    P2RacBl
    P2RacBH
    P2RacWh
    P2RacUD
    Per2Ethn
    Per2Mil
    Per2Pior
    Per2Mal1
    Per2Mal2
    Per2Mal3
    Per2Mal4
    Per3ID
    Per3Rel
    Per3Prnt
    Per3Cr
    Per3Age
    Per3Sex
    P3RacAI
    P3RacAs
    P3RacBl
    P3RacBH
    P3RacWh
    P3RacUD
    Per3Ethn
    Per3Mil
    Per3Pior
    Per3Mal1
    Per3Mal2
    Per3Mal3
    Per3Mal4
);

my $child_csv
    = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
my $report_csv
    = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
open my $child_fh, ">:encoding(utf8)", $child_csv_file
    or die "$child_csv_file: $!";
open my $report_fh, ">:encoding(utf8)", $report_csv_file
    or die "$report_csv_file: $!";
$child_csv->column_names( \@CHILD_FIELDS );
$child_csv->print( $child_fh, \@CHILD_FIELDS );
$report_csv->column_names( \@REPORT_FIELDS );
$report_csv->print( $report_fh, \@REPORT_FIELDS );

my $DEBUG = $ENV{DEBUG} || 0;

# we want the most "complete" (i.e. final) report row for each Removal.
# we know there's a new Removal each time TotalRem increments.
while ( my $child = $children_sth->fetchrow_hashref() ) {
    $reports_sth->execute( $child->{ChID} );
    my $reports = $reports_sth->fetchall_arrayref( {} );
    $DEBUG and dump $child;
    my $previous_report;
    my @complete_reports = ();
    for my $report (@$reports) {
        $DEBUG and dump $report;
        $DEBUG and printf( "%s-%s\n", $report->{RptDt}, $report->{RptTm} );
        for my $date (@dates) {
            $DEBUG and printf( "%8s %10s  ", $date, $report->{$date} );
        }
        $previous_report = $report;

        $DEBUG and print "\n";
    }
    push @complete_reports,
        $previous_report;    # last one is always most complete

    for my $report (@complete_reports) {

        $DEBUG and dump $report;
        $report_csv->print_hr( $report_fh, $report );
    }

    $DEBUG and print "=" x 80, $/;

    $child_csv->print_hr( $child_fh, $child );
}
