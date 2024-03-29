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
    "E01_FIPS_CODE"                  => "State",
    "E03_LOCAL_FIPS_CODE"            => "FIPSCode",
    "E04_RECORD_NUMBER"              => "RecNumbr",
    "E05_RECENT_REVIEW_DATE"         => "PedRevDt",
    "E06_BIRTH_DATE"                 => "DOB",
    "E07_SEX"                        => "Sex",
    "E08A_RACE_NATIVE_AMER"          => "AmIAKN",
    "E08B_RACE_ASIAN"                => "Asian",
    "E08C_RACE_AFRICAN_AMER"         => "BlkAfrAm",
    "E08D_RACE_NATIVE_HAWAIIAN"      => "HawaiiPI",
    "E08E_RACE_WHITE"                => "White",
    "E08F_RACE_UNABLE_TO_DETER"      => "UnToDetm",
    "E09_HISPANIC"                   => "HisOrgin",
    "E10_DISABILITIES"               => "ClinDis",
    "E11_MENTAL_RETARDATION"         => "MR",
    "E12_VISUALLY_HEARING"           => "VisHear",
    "E13_PHYSICALLY_DISABLED"        => "PhyDis",
    "E14_EMOTIONALLY_DISTURBED"      => "EmotDist",
    "E15_OTHER_MEDICAL_CONDI"        => "OtherMed",
    "E16_CHILD_EVER_ADOPTED"         => "EverAdpt",
    "E17_AGE_AT_PREV_ADOPTION"       => "AgeAdopt",
    "E18_1ST_REVMOAL_DATE"           => "Rem1Dt",
    "E19_TOTAL_NUM_REMOVALS"         => "TotalRem",
    "E20_LAST_EPISODE_DISCHARGE_DT"  => "DLstFCDt",
    "E21_LATEST_REMOVAL_DATE"        => "LatRemDt",
    "E22_LATEST_REMOVAL_TS"          => "RemTrnDt",
    "E23_CURR_FC_PLAC_START_DATE"    => "CurSetDt",
    "E24_NUMBER_OF_PLACEMENTS"       => "NumPlep",
    "E25_REMOVAL_FROM_HOME"          => "ManRem",
    "E26_PHYSICAL_ABUSE"             => "PhyAbuse",
    "E27_SEXUAL_ABUSE"               => "SexAbuse",
    "E28_NEGLECT"                    => "Neglect",
    "E29_ALCOHOL_ABUSE_PARENT"       => "AAParent",
    "E30_DRUG_ABUSE_PARENT"          => "DAParent",
    "E31_ALCOHOL_ABUSE_CHILD"        => "AAChild",
    "E32_DRUG_ABUSE_CHILD"           => "DAChild",
    "E33_CHILD_DISABILITY"           => "ChilDis",
    "E34_CHILD_BEHAVIOR_PROBLEM"     => "ChBehPrb",
    "E35_DEATH_OF_PARENT"            => "PrtsDied",
    "E36_INCARCERATION_OF_PARENT"    => "PrtsJail",
    "E37_CARETAKER_INABILITY_2_COPE" => "NoCope",
    "E38_ABANDONMENT"                => "Abandmnt",
    "E39_RELINQUISHMENT"             => "Relinqsh",
    "E40_INADEQUATE_HOUSING"         => "Housing",
    "E41_CURR_PLACEMENT_SETTING"     => "CurPlSet",
    "E42_PLACEMENT_OUT_OF_STATE"     => "PlaceOut",
    "E43_CASE_PLAN_GOAL"             => "CaseGoal",
    "E44_CARETAKER_FAMILY_STRUCTURE" => "CtkFamSt",
    "E45_1ST_CARETAKER_BIRTH_YEAR"   => "CTK1YR",
    "E46_2ND_CARETAKER_BIRTH_YEAR"   => "CTK2YR",
    "E47_MOTHER_TPR_DATE"            => "TPRMomDt",
    "E48_FATHER_TPR_DATE"            => "TPRDadDt",
    "E49_FC_FAMILY_STRUCTURE"        => "FosFamSt",
    "E50_1ST_FC_BIRTH_YEAR"          => "FCCTK1YR",
    "E51_2ND_FC_BIRTH_YEAR"          => "FCCTK2YR",
    "E52A_1ST_FC_RACE_NATIVE_AMER"   => "RF1AMAKN",
    "E52B_1ST_FC_RACE_ASIAN"         => "RF1ASIAN",
    "E52C_1ST_FC_RACE_AFRICAN_AMER"  => "RF1BLKAA",
    "E52D_1ST_FC_RACE_NATIVE_HAWAII" => "RF1NHOPI",
    "E52E_1ST_FC_RACE_WHITE"         => "RF1WHITE",
    "E52F_1ST_FC_RACE_UNABLE_TO_DET" => "RF1UTOD",
    "E53_1ST_FC_HISPANIC"            => "HOFCCTK1",
    "E54A_2ND_FC_RACE_NATIVE_AMER"   => "RF2AMAKN",
    "E54B_2ND_FC_RACE_ASIAN"         => "RF2Asian",
    "E54C_2ND_FC_RACE_AFRICAN_AMER"  => "RF2BLKAA",
    "E54D_2ND_FC_RACE_NATIVE_HAWAII" => "RF2NHOPI",
    "E54E_2ND_FC_RACE_WHITE"         => "RF2WHITE",
    "E54F_2ND_FC_RACE_UNABLE_TO_DET" => "RF2UTOD",
    "E55_2ND_FC_HISPANIC"            => "HOFCCTK2",
    "E56_FC_DISCHARGE_DATE"          => "DoDFCDt",
    "E57_FC_DISCHARGE_TS"            => "DoDTrnDt",
    "E58_FC_DISCHARGE_REASON"        => "DISREASN",
    "E59_TITLE_IVE_FC"               => "IVEFC",
    "E60_TITLE_IVE_ADOP"             => "IVEAA",
    "E61_TITLE_IVA"                  => "IVAAFDC",
    "E62_TITLE_IVD"                  => "IVDCHSUP",
    "E63_TITLE_XIX"                  => "XIXMEDCD",
    "E64_SSI_OTHER"                  => "SSIOther",
    "E65_OTHER_FEDERAL_SUPPORT"      => "NOA",
    "E66_SUBSIDY_AMOUNT"             => "FCMntPay",
);

# warn just once per file
my %warned = ();

my @yes_no_unable = qw(
    HisOrgin
    ClinDis
    EverAdpt
    PlaceOut
    HOFCCTK1
    HOFCCTK2
);

my %age_adopt = (
    ""                        => "",
    "not applicable"          => 0,
    "less then two years old" => 1,    # sic then
    "2 to 5 years old"        => 2,
    "6 to 12 years old"       => 3,
    "13 years old or older"   => 4,
    "unable to determine"     => 5,
);

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

my %removal_manner = (
    ""                   => "",
    "voluntary"          => 1,
    "court ordered"      => 2,
    "not yet determined" => 3,
);

my %current_placement = (
    ""                                => "",
    "pre-adoptive home"               => 1,
    "foster family home relative"     => 2,
    "foster family home non-relative" => 3,
    "group home"                      => 4,
    "institution"                     => 5,
    "supervised independent living"   => 6,
    "runaway"                         => 7,
    "trial home visit"                => 8,
);

my %case_goal = (
    ""                                            => "",
    "runify with parents or principal caretakers" => 1,    # sic runify
    "living with other relatives"                 => 2,
    "live with other relatives"                   => 2,
    "adoption"                                    => 3,
    "long term foster care"                       => 4,
    "emancipation"                                => 5,
    "guardianship"                                => 6,
    "case plan goal not yet established"          => 7,
);

my %caretaker = (
    ""                    => 5,
    "married couple"      => 1,
    "unmarried couple"    => 2,
    "single female"       => 3,
    "single male"         => 4,
    "unable to determine" => 5,
);

my %foster_family = (
    ""                 => 0,
    "not applicable"   => 0,
    "married couple"   => 1,
    "unmarried couple" => 2,
    "single female"    => 3,
    "single male"      => 4,
);

my %yes_no = (
    ""    => "",
    "0"   => 0,
    "1"   => 1,
    "no"  => 0,
    "yes" => 1,
);

my %discharge = (
    "not applicable"                                   => 0,
    "reunification with parents or primary caretakers" => 1,
    "living with other relatives"                      => 2,
    "adoption"                                         => 3,
    "emancipation"                                     => 4,
    "guardianship"                                     => 5,
    "transfer to another agency"                       => 6,
    "runaway"                                          => 7,
    "death of child"                                   => 8,
);

sub remap {
    my ( $rec, $field, $map ) = @_;
    if ( !exists $map->{ lc( $rec->{$field} ) } ) {
        warn "No mapping for $field => $rec->{$field} in map";
        return;
    }
    $rec->{$field} = $map->{ lc( $rec->{$field} ) };
}

sub norm_rec {
    my ( $file, $rec ) = @_;

    my $normed = {};
    for my $k ( keys %$rec ) {
        next if $k eq "E02_RPT_PERIOD_END_DATE";
        if ( !exists $MAP{$k} ) {
            warn "$file: Key $k not in MAP" unless $warned{$file}->{$k}++;
            $normed->{$k} = $rec->{$k};
            next;
        }
        $normed->{ $MAP{$k} } = $rec->{$k};
    }
    my ( $rep_year, $rep_month )
        = ( $rec->{E02_RPT_PERIOD_END_DATE} =~ /^(\d\d\d\d)(\d\d)/ );
    $normed->{RepDatMo} = $rep_month;
    $normed->{RepDatYr} = $rep_year;

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
        next unless defined $normed->{$k};
        if ( lc( $normed->{$k} ) =~ m/does not apply$/ ) {
            $normed->{$k} = 0;
        }
        elsif ( lc( $normed->{$k} ) =~ m/applies$/ ) {
            $normed->{$k} = 1;
        }
    }
    if ( $normed->{Sex} eq "Male" )   { $normed->{Sex} = 1 }
    if ( $normed->{Sex} eq "Female" ) { $normed->{Sex} = 2 }

    for my $f (@yes_no_unable) {
        if ( lc( $normed->{$f} ) eq "not applicable" ) { $normed->{$f} = 0 }
        if ( lc( $normed->{$f} ) eq "yes" )            { $normed->{$f} = 1 }
        if ( lc( $normed->{$f} ) eq "no" )             { $normed->{$f} = 2 }
        if ( lc( $normed->{$f} ) =~ /determine/ )      { $normed->{$f} = 3 }
    }

    remap( $normed, "AgeAdopt", \%age_adopt );

    for my $f (@dates) {
        $normed->{$f} = parse_date_iso( $normed->{$f} );
    }

    remap( $normed, "ManRem",   \%removal_manner );
    remap( $normed, "CurPlSet", \%current_placement );
    remap( $normed, "CaseGoal", \%case_goal );
    remap( $normed, "CtkFamSt", \%caretaker );
    remap( $normed, "FosFamSt", \%foster_family );
    remap( $normed, "RF1UTOD",  \%yes_no );
    remap( $normed, "DISREASN", \%discharge );

    return $normed;
}

for my $json_file (@ARGV) {
    my $buf       = read_json($json_file);
    my $first_rec = $buf->[0];
    my %not_in_map
        = map { $_ => $_ } grep { $_ and !exists $MAP{$_} } keys %$first_rec;
    my $header   = [ @CSV_HEADER, keys %not_in_map ];
    my $csv_file = $json_file;
    $csv_file =~ s/\.json$/-norm.csv/;
    my $csv
        = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
    $csv->column_names($header);
    open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
    $csv->print( $fh, $header );

    for my $rec (@$buf) {
        my $normed = norm_rec( $json_file, $rec );

        $csv->print_hr( $fh, $normed );
    }

    close $fh;
}

