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

my $dbfile = "$FindBin::Bin/../eval/ncands.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, AutoCommit => 1, } );
my $children = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'children',
);
my $reports = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'reports',
);
my $perps = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'perps',
);

my @CHILD_FIELDS = qw(
    SubYr
    StaTerr
    ChID
    ChAge
    ChSex
    ChRacAI
    ChRacAs
    ChRacBl
    ChRacNH
    ChRacWh
    ChRacUd
    CEthn
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
    AFCARSID
    FCDchDt
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
);

my @PERP_FIELDS = qw(
    SubYr
    StaTerr
    ChID
    RptID
);

my @PERP_ATTRS = qw(
    ID
    Rel
    Prnt
    Cr
    Age
    Sex
    RacAI
    RacAs
    RacBl
    RacBH
    RacWh
    RacUD
    Ethn
    Mil
    Pior
    Mal1
    Mal2
    Mal3
    Mal4
);

sub get_child {
    my $row = shift;
    return unless $row->{ChID};
    my $child = { id => join( "-", $row->{ChID}, $row->{RptID} ), };
    for my $f (@CHILD_FIELDS) {
        $child->{$f} = $row->{$f};
    }
    return $child;
}

sub get_report {
    my $row = shift;
    return unless $row->{RptID};
    my $report = { id => $row->{RptID} };
    for my $f (@REPORT_FIELDS) {
        $report->{$f} = $row->{$f};
    }
    return $report;
}

sub get_perps {
    my $row   = shift;
    my @perps = ();
    for my $n ( ( 1, 2, 3 ) ) {
        next unless $row->{"Per${n}ID"};
        my $perp = { id => $row->{"Per${n}ID"} };
        for my $f (@PERP_FIELDS) {
            $perp->{$f} = $row->{$f};
        }
        for my $f (@PERP_ATTRS) {
            my $field = "Per${n}$f";
            if ( $f =~ /Rac/ ) {
                $field = "P${n}$f";
            }
            $perp->{$f} = $row->{$field};
        }
        push @perps, $perp;
    }
    return @perps;
}

my %report_ids = ();

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
        my $child = get_child($row);
        next unless $child;
        my $report = get_report($row);
        $report->{filename} = $csv_file;
        $reports->insert($report) unless $report_ids{ $report->{id} }++;
        $children->insert($child);
        for my $p ( get_perps($row) ) {
            $perps->insert($p);
        }
        $progress->update();
    }

    $dbh->commit;
}
