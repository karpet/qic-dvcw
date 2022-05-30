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
    "select * from reports where ChID = ? order by RptID asc, RpDispDt asc");
my $children_sth;

if (@ARGV) {
    $children_sth = $dbh->prepare("select * from children where ChID in (?)");
    $children_sth->execute(@ARGV);
}
else {
    $children_sth = $dbh->prepare("select * from children");
    $children_sth->execute();
}

my @dates = qw(
    RptDt
    InvDate
    RpDispDt
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
    ChRacUD
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
    P1RacNH
    P1RacWh
    P1RacUd
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
    P2RacNH
    P2RacWh
    P2RacUd
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
    P3RacNH
    P3RacWh
    P3RacUd
    Per3Ethn
    Per3Mil
    Per3Pior
    Per3Mal1
    Per3Mal2
    Per3Mal3
    Per3Mal4
);

# extras fields as individual columns
my @mass_extras = (
    "QIC Person ID",
    "QIC Investigation ID",
    "REGION_NAME",
    "AREA_NAME",
    "QIC Case ID"
);
my @ill_extras = qw(
    cd_find
    PER3ID_id_pers
    PER2ID_id_pers
    ID_INVST_CASE
    DT_DCSD ID_SCR_SEQ
    SUPRVID_id_pers
    DT_INVST_RPT
    CYCIS_SERV_DATE
    DT_INCDT
    PER1ID_id_pers
    DT_FIND
    TM_INVST_RPT
    CYCIS_RMVL_DATE
    ID_INVST
    CYCIS_PET_DATE
    chid_id_pers
    id_org_ent
    DT_OF_BIRTH
    LIVAR_END_DT
    AFCARSID_cycis_case_id
    WRKRID_id_pers
    ID_INVST_SUBJ
);
my @pa_extras = (

);

push @REPORT_FIELDS, @mass_extras, @ill_extras, @pa_extras;

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

while ( my $child = $children_sth->fetchrow_hashref() ) {
    $reports_sth->execute( $child->{ChID} );
    my $reports = $reports_sth->fetchall_arrayref( {} );
    $DEBUG and dump $child;
    my $previous_report;
    my @complete_reports = ();
    for my $report (@$reports) {

        # $DEBUG and dump $report;
        $DEBUG and printf( "%s %s %s-%s\n",
            $report->{RptID}, $report->{RpDispDt},
            $report->{RptDt}, $report->{RptTm} );
        for my $date (@dates) {

            #$DEBUG and printf( "%8s %10s  ", $date, $report->{$date} );
        }
        $previous_report ||= $report;

        if ( $previous_report->{RptID} ne $report->{RptID} ) {
            push @complete_reports, $previous_report;
        }

        $previous_report = $report;

        # $DEBUG and print "\n";
    }

    # last one is always most complete
    push @complete_reports, $previous_report;

    for my $report (@complete_reports) {

        #$DEBUG and dump $report;
        $DEBUG and printf( "complete %s %s %s\n",
            $report->{RptID}, $report->{RptDt}, $report->{RpDispDt} );

        my $extras = JSON::decode_json( delete $report->{extras} );
        for my $k ( keys %$extras ) {
            next if exists $report->{$k};
            $report->{$k} = $extras->{$k};
        }

        $report_csv->print_hr( $report_fh, $report );
    }

    $DEBUG and print "=" x 80, $/;

    $child_csv->print_hr( $child_fh, $child );
}
