#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON;
use Text::CSV_XS qw( csv );
use Data::Dump qw( dump );
use DBI;

my $child_csv_file   = shift(@ARGV) || "children.csv";
my $episode_csv_file = shift(@ARGV) || "episodes.csv";

my $dbfile = "$FindBin::Bin/../eval/afcars.db";
my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "",
    { RaiseError => 1, } );

my $episodes_sth
    = $dbh->prepare(
    "select * from episodes where child_id = ? order by RepDatYr asc, RepDatMo asc"
    );
my $children_sth = $dbh->prepare("select * from children");

$children_sth->execute();

my @dates = qw(
    PedRevDt
    Rem1Dt
    DLstFCDt
    LatRemDt
    RemTrnDt
    CurSetDt
    DoDFCDt
    DoDTrnDt
);

my @CHILD_FIELDS = qw(
    StFCID
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
    TotalRem
);

my @EPISODE_FIELDS = qw(
    StFCID
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

# extras fields as individual columns
my @mass_extras = (
    "AREA_NAME",     "E02_RPT_PERIOD_END_DATE",
    "REGION_NAME",   "QIC Case ID",
    "QIC Person ID", "E03_LOCAL_COUNTY"
);
my @ill_extras = ("E2RptPrdEndCCYYMM");
my @pa_extras  = (

);

push @EPISODE_FIELDS, @mass_extras, @ill_extras, @pa_extras;

my $child_csv
    = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
my $episode_csv
    = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
open my $child_fh, ">:encoding(utf8)", $child_csv_file
    or die "$child_csv_file: $!";
open my $episode_fh, ">:encoding(utf8)", $episode_csv_file
    or die "$episode_csv_file: $!";
$child_csv->column_names( \@CHILD_FIELDS );
$child_csv->print( $child_fh, \@CHILD_FIELDS );
$episode_csv->column_names( \@EPISODE_FIELDS );
$episode_csv->print( $episode_fh, \@EPISODE_FIELDS );

my $DEBUG = $ENV{DEBUG} || 0;

# we want the most "complete" (i.e. final) episode row for each Removal.
# we know there's a new Removal each time TotalRem increments.
while ( my $child = $children_sth->fetchrow_hashref() ) {
    $episodes_sth->execute( $child->{id} );
    my $episodes = $episodes_sth->fetchall_arrayref( {} );
    $DEBUG and dump $child;
    my $total_removals
        = $episodes->[0]->{TotalRem};    # baseline is first episode
    my $removal_changes = 1;             # assume first removal 0 -> 1
    my $previous_episode;
    my @complete_episodes = ();
    for my $episode (@$episodes) {
        $DEBUG and dump $episode;
        $DEBUG
            and
            printf( "%s-%s\n", $episode->{RepDatYr}, $episode->{RepDatMo} );
        for my $f (qw( TotalRem NumPlep )) {
            $DEBUG and printf( "%8s %s\n", $f, $episode->{$f} );
        }
        for my $date (@dates) {
            $DEBUG and printf( "%8s %10s  ", $date, $episode->{$date} );
        }
        $total_removals ||= $episode->{TotalRem};
        if ( $total_removals ne $episode->{TotalRem} ) {
            $DEBUG and printf( "TotalRem changed: %s -> %s\n",
                $total_removals, $episode->{TotalRem} );
            $total_removals = $episode->{TotalRem};
            $removal_changes++;
            push @complete_episodes, $previous_episode;
        }
        $previous_episode = $episode;

        $DEBUG and print "\n";
    }
    push @complete_episodes,
        $previous_episode;    # last one is always most complete

    if ( $removal_changes != scalar(@complete_episodes) ) {
        die "Failed to capture $removal_changes complete episodes for child "
            . dump($child);
    }

    for my $episode (@complete_episodes) {

        #dump $episode;
        $episode->{StFCID} = $episode->{child_id};
        my $extras = JSON::decode_json( delete $episode->{extras} );
        for my $k ( keys %$extras ) {
            $episode->{$k} = $extras->{$k};
        }

        $episode_csv->print_hr( $episode_fh, $episode );
    }

    $DEBUG and print "=" x 80, $/;
    $child->{StFCID}   = $child->{id};
    $child->{TotalRem} = $total_removals;

    # assume last episode has most current demo flags for some child fields
    for my $f (
        qw( ClinDis MR VisHear PhyDis EmotDist OtherMed EverAdpt AgeAdopt ))
    {
        my $recent = $complete_episodes[-1]->{$f};
        if ( $child->{$f} ne $recent ) {

            # TODO
            $DEBUG
                and
                printf( "Updating %s %s -> %s\n", $f, $child->{$f}, $recent );

            #$child->{$f} = $recent;
        }
    }

    $child_csv->print_hr( $child_fh, $child );
}
