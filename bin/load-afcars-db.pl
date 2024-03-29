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

my $dbfile = "$FindBin::Bin/../eval/afcars.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, } );
my $children = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'children',
);
my $episodes = DBIx::InsertHash->new(
    quote => 1,
    dbh   => $dbh,
    table => 'episodes',
);

my @CHILD_FIELDS = qw(
    State
    RecNumbr
    DOB
    Sex
    AmIAKN
    Asian
    BlkAfrAm
    HawaiiPI
    White
    UnToDetm
    HisOrgin
    ClinDis
    MR
    VisHear
    PhyDis
    EmotDist
    OtherMed
    EverAdpt
    AgeAdopt
    Rem1Dt
);

my @EPISODE_FIELDS = qw(
    RepDatMo
    RepDatYr
    FIPSCode
    PedRevDt
    ClinDis
    MR
    VisHear
    PhyDis
    EmotDist
    OtherMed
    EverAdpt
    AgeAdopt
    Rem1Dt
    TotalRem
    DLstFCDt
    LatRemDt
    RemTrnDt
    CurSetDt
    NumPlep
    ManRem
    PhyAbuse
    SexAbuse
    Neglect
    AAParent
    DAParent
    AAChild
    DAChild
    ChilDis
    ChBehPrb
    PrtsDied
    PrtsJail
    NoCope
    Abandmnt
    Relinqsh
    Housing
    CurPlSet
    PlaceOut
    CaseGoal
    CtkFamSt
    CTK1YR
    CTK2YR
    TPRMomDt
    TPRDadDt
    FosFamSt
    FCCTK1YR
    FCCTK2YR
    RF1AMAKN
    RF1ASIAN
    RF1BLKAA
    RF1NHOPI
    RF1WHITE
    RF1UTOD
    HOFCCTK1
    RF2AMAKN
    RF2Asian
    RF2BLKAA
    RF2NHOPI
    RF2WHITE
    RF2UTOD
    HOFCCTK2
    DoDFCDt
    DoDTrnDt
    DISREASN
    IVEFC
    IVEAA
    IVAAFDC
    IVDCHSUP
    XIXMEDCD
    SSIOther
    NOA
    FCMntPay
);

sub get_child {
    my $row = shift;
    return unless $row->{RecNumbr};
    my $child = { id => join( "-", $row->{State}, $row->{RecNumbr} ), };
    for my $f (@CHILD_FIELDS) {
        $child->{$f} = $row->{$f};
    }
    return $child;
}

sub get_episode {
    my $row = shift;
    return unless $row->{RecNumbr};
    my $episode
        = { child_id => join( "-", $row->{State}, $row->{RecNumbr} ), };
    for my $f (@EPISODE_FIELDS) {
        $episode->{$f} = $row->{$f};
    }
    return $episode;
}

my %child_ids = ();

for my $csv_file (@ARGV) {
    print "Loading: $csv_file\n";
    my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
    open my $fh, "<", $csv_file;
    my @headers = $csv->header($fh);

    my $rows = csv( in => $csv_file, headers => "auto" );

    $dbh->begin_work;

    for my $row (@$rows) {
        my $child = get_child($row);
        next unless $child;
        my $episode = get_episode($row);
        $episode->{filename} = $csv_file;
        my %extras = ();
        for my $k (keys %$row) {
            if ( !exists $episode->{$k} and !exists $child->{$k} ) {
                $extras{$k} = $row->{$k};
            }
        }
        $episode->{extras} = JSON::encode_json( \%extras );
        $children->insert($child) unless $child_ids{ $child->{id} }++;
        $episodes->insert($episode);
    }

    $dbh->commit;
}
