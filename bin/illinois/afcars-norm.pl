#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_iso read_json trim );

# AFCARS col heads
my @CSV_HEADER = read_lines("$FindBin::Bin/../../eval/afcars-vars.txt");

# dump \@CSV_HEADER;

my %MAP = (
    "E1State"               => "State",
    "E3LocalAgency"         => "FIPSCode",
    "E4RecordNum"           => "RecNumbr",
    "E5MostRecntRevDateGRP" => "PedRevDt",
    "E6BirthDateGrp"        => "DOB",
    "E7SexCode"             => "Sex",
    "E8ARaceCode"           => "AmIAKN",
    "E8BRaceCode"           => "Asian",
    "E8CRaceCode"           => "BlkAfrAm",
    "E8DRaceCode"           => "HawaiiPI",
    "E8ERaceCode"           => "White",
    "E8FRaceCode"           => "UnToDetm",
    "E9HispOrigin"          => "HisOrgin",
    "E10DiagnsdDisab"       => "ClinDis",
    "E11MntlRetardation"    => "MR",
    "E12VisHrngImprd"       => "VisHear",
    "E13PhysDisab"          => "PhyDis",
    "E14EmotDistrbd"        => "EmotDist",
    "E15OtherMed"           => "OtherMed",
    "E16ChldAdopted"        => "EverAdpt",
    "E17AgeAdopted"         => "AgeAdopt",
    "E18FirstRmvlDate"      => "Rem1Dt",
    "E19totalTotalRmvlCnt"  => "TotalRem",
    "E20DischLastFCDate"    => "DLstFCDt",
    "E21LatestRmvlDate"     => "LatRemDt",
    "E22RmvlTransDate"      => "RemTrnDt",
    "E23CurrPlcmntDate"     => "CurSetDt",
    "E24PrevPlcmntEpisCnt"  => "NumPlep",
    "E25RmvlMannerCode"     => "ManRem",
    "E26PhysAbuseInd"       => "PhyAbuse",
    "E27SexAbuseInd"        => "SexAbuse",
    "E28NeglectInd"         => "Neglect",
    "E29ALCAbusePrntInd"    => "AAParent",
    "E30DrugAbusePrntInd"   => "DAParent",
    "E31ALCAbuseChildInd"   => "AAChild",
    "E32DrugAbuseChldInd"   => "DAChild",
    "E33ChldDisabilityInd"  => "ChilDis",
    "E34ChldBehavPrblmInd"  => "ChBehPrb",
    "E35DthPrntInd"         => "PrtsDied",
    "E36IncarcPrntInd"      => "PrtsJail",
    "E37CrtkrIllnessInd"    => "NoCope",
    "E38AbandonmentInd"     => "Abandmnt",
    "E39RelinquishmentInd"  => "Relinqsh",
    "E40InadeqHsngInd"      => "Housing",
    "E41CurrPlcmntCode"     => "CurPlSet",
    "E42CurrPlcmntOSInd"    => "PlaceOut",
    "E43CasePlanCode"       => "CaseGoal",
    "E44CrtkrFamStruct"     => "CtkFamSt",
    "E45FrstCrtkrBirthCCYY" => "CTK1YR",
    "E46ScndCrtkrBirthCCYY" => "CTK2YR",
    "E47MoPrTermDate"       => "TPRMomDt",
    "E48FaPrTermDate"       => "TPRDadDt",
    "E49FamilyStruct"       => "FosFamSt",
    "E50FrstFPBirthCCYY"    => "FCCTK1YR",
    "E51ScndFPBirthCCYY"    => "FCCTK2YR",
    "E52ARaceCode"          => "RF1AMAKN",
    "E52BRaceCode"          => "RF1ASIAN",
    "E52CRaceCode"          => "RF1BLKAA",
    "E52DRaceCode"          => "RF1NHOPI",
    "E52ERaceCode"          => "RF1WHITE",
    "E52FRaceCode"          => "RF1UTOD",
    "E53FrstFPHispOrigin"   => "HOFCCTK1",
    "E54ARaceCode"          => "RF2AMAKN",
    "E54BRaceCode"          => "RF2Asian",
    "E54CRaceCode"          => "RF2BLKAA",
    "E54DRaceCode"          => "RF2NHOPI",
    "E54ERaceCode"          => "RF2WHITE",
    "E54FRaceCode"          => "RF2UTOD",
    "E55ScndFPHispOrigin"   => "HOFCCTK2",
    "E56DischDate"          => "DoDFCDt",
    "E57DischTransDate"     => "DoDTrnDt",
    "E58DischReasonCode"    => "DISREASN",
    "E59TIVEFC"             => "IVEFC",
    "E60TIVEAA"             => "IVEAA",
    "E61TIVAAFDC"           => "IVAAFDC",
    "E62TIVDChldSupp"       => "IVDCHSUP",
    "E63TXIXMedicaid"       => "XIXMEDCD",
    "E64SSISSA"             => "SSIOther",
    "E65NoneAbove"          => "NOA",
    "E66AmtMnthlyFCPmtA"    => "FCMntPay",
);

# warn just once per file
my %warned = ();

my @dates = qw(
    DOB
    PedRevDt
    Rem1Dt
    DLstFCDt
    LatRemDt
    RemTrnDt
    CurSetDt
    TPRMomDt
    TPRDadDt
    DoDFCDt
    DoDTrnDt
);

sub norm_rec {
    my ( $file, $rec ) = @_;

    my $normed = {};
    for my $k ( keys %$rec ) {
        next if $k eq "E2RptPrdEndCCYYMM";
        next if $k eq "ADP2RptDateCCYYMM";
        if ( !exists $MAP{$k} ) {
            warn "$file: Key $k not in MAP" unless $warned{$file}->{$k}++;
            $normed->{$k} = $rec->{$k};
            next;
        }
        $normed->{ $MAP{$k} } = $rec->{$k};
    }
    if ( exists $rec->{"ADP2RptDateCCYYMM"} ) {
        my ( $rep_year, $rep_month )
            = ( $rec->{ADP2RptDateCCYYMM} =~ /^(\d\d\d\d)(\d\d)/ );
        $normed->{RepDatMo} = $rep_month;
        $normed->{RepDatYr} = $rep_year;
    }
    else {
        my ( $rep_year, $rep_month )
            = ( $rec->{E2RptPrdEndCCYYMM} =~ /^(\d\d\d\d)(\d\d)/ );
        $normed->{RepDatMo} = $rep_month;
        $normed->{RepDatYr} = $rep_year;
    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    for my $f (@dates) {
        $normed->{$f} = parse_date_iso( $normed->{$f} );
    }

    return $normed;
}

for my $json_file (@ARGV) {
    my $buf      = read_json($json_file);
    my $csv_file = $json_file;
    $csv_file =~ s/\.json$/-norm.csv/;
    my $csv
        = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
    $csv->column_names( \@CSV_HEADER );
    open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
    $csv->print( $fh, \@CSV_HEADER );

    for my $rec (@$buf) {
        my $normed = norm_rec( $json_file, $rec );

        $csv->print_hr( $fh, $normed );
    }

    close $fh;
}

