#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_iso parse_date_mdy read_json trim );

my $ncands_fields = csv(
    in      => "$FindBin::Bin/../../eval/ncands-vars.csv",
    headers => "auto"
);
my @csv_header = map { $_->{name} } @$ncands_fields;
push @csv_header, "DOB";    # unofficial

my %MAP = (
    "QIC Investigation ID"           => "",
    "QIC Person ID"                  => "",
    "REGION_NAME"                    => "",
    "AREA_NAME"                      => "",
    "QIC Case ID"                    => "",
    "E01_SUBYR"                      => "SubYr",
    "E02_STATERR"                    => "StaTerr",
    "E03_RPT_ID"                     => "RptID",
    "E04_CHID"                       => "ChID",
    "E05_RPTCNTY"                    => "RptFIPS",
    "E06_RPTDT"                      => "RptDt",
    "E07_INVDATE"                    => "InvDate",
    "E08_RPTSRC"                     => "RptSrc",
    "E09_RPTDISP"                    => "RptDisp",
    "E10_RPTDISDT"                   => "RpDispDt",
    "E11_NOTIFS"                     => "Notifs",
    "E12_CHAGE"                      => "ChAge",
    "E13_CHBDATE"                    => "DOB",
    "E14_CHSEX"                      => "ChSex",
    "E15_CHRACAI_RACE_AMER_INDIAN"   => "ChRacAI",
    "E16_CHRACAS_RACE_ASIAN"         => "ChRacAs",
    "E17_CHRACBL_RACE_BLACK"         => "ChRacBl",
    "E18_CHRACNH_RACE_NATIVE_HAWAII" => "ChRacNH",
    "E19_CHRACWH_RACE_WHITE"         => "ChRacWh",
    "E20_CHRACUD_RACE_UNABLE_TO_DET" => "ChRacUD",
    "E21_CHETHN"                     => "CEthn",
    "E22_CHCNTY"                     => "ChCnty",
    "E23_CHLVNG"                     => "ChLvng",
    "E24_CHMIL"                      => "ChMil",
    "E25_CHPRIOR"                    => "ChPrior",
    "E26_CHMAL1"                     => "ChMal1",
    "E27_MAL1LEV"                    => "Mal1Lev",
    "E28_CHMAL2"                     => "ChMal2",
    "E29_MAL2LEV"                    => "Mal2Lev",
    "E30_CHMAL3"                     => "ChMal3",
    "E31_MAL3LEV"                    => "Mal3Lev",
    "E32_CHMAL4"                     => "ChMal4",
    "E33_MAL4LEV"                    => "Mal4Lev",
    "E34_MALDEATH"                   => "MalDeath",
    "E35_CDALC"                      => "CdAlc",
    "E36_CDDRUG"                     => "CdDrug",
    "E37_CDRTRD"                     => "CdRtrd",
    "E38_CDEMOTNL"                   => "CdEmotnl",
    "E39_CDVISUAL"                   => "CdVisual",
    "E40_CDLEARN"                    => "CdLearn",
    "E41_CDPHYS"                     => "CdPhys",
    "E42_CDBEHAV"                    => "CdBehav",
    "E43_CDMEDICL"                   => "CdMedicl",
    "E44_FCALC"                      => "FCAlc",
    "E45_FCDRUG"                     => "FCDrug",
    "E46_FCRTRD"                     => "FCRtrd",
    "E47_FCEMOTNL"                   => "FCEmotnl",
    "E48_FCVISUAL"                   => "FCVisual",
    "E49_FCLEARN"                    => "FCLearn",
    "E50_FCPHYS"                     => "FCPhys",
    "E51_FCMEDICL"                   => "FCMedicl",
    "E52_FCVIOL"                     => "FCViol",
    "E53_FCHOUSE"                    => "FCHouse",
    "E54_FCMONEY"                    => "FCMoney",
    "E55_FCPUBLIC"                   => "FCPublic",
    "E56_POSTSERV"                   => "PostServ",
    "E57_SERVDATE"                   => "ServDate",
    "E58_FAMSUP"                     => "FamSup",
    "E59_FAMPRES"                    => "FamPres",
    "E60_FOSTERCR"                   => "FosterCr",
    "E61_RMVDATE"                    => "RmvDate",
    "E62_JUVPET"                     => "JuvPet",
    "E63_PETDATE"                    => "PetDate",
    "E64_COCHREP"                    => "CoChRep",
    "E65_ADOPT"                      => "Adopt",
    "E66_CASEMANG"                   => "CaseMang",
    "E67_COUNSEL"                    => "Counsel",
    "E68_DAYCARE"                    => "Daycare",
    "E69_EDUCATN"                    => "Educatn",
    "E70_EMPLOY"                     => "Employ",
    "E71_FAMPLAN"                    => "FamPlan",
    "E72_HEALTH"                     => "Health",
    "E73_HOMEBASE"                   => "Homebase",
    "E74_HOUSING"                    => "Housing",
    "E75_TRANSLIV"                   => "TransLiv",
    "E76_INFOREF"                    => "InfoRef",
    "E77_LEGAL"                      => "Legal",
    "E78_MENTHLTH"                   => "MentHlth",
    "E79_PREGPAR"                    => "PregPar",
    "E80_RESPITE"                    => "Respite",
    "E81_SSDISABL"                   => "SSDisabl",
    "E82_SSDELINQ"                   => "SSDelinq",
    "E83_SUBABUSE"                   => "SubAbuse",
    "E84_TRANSPRT"                   => "Transprt",
    "E85_OTHERSV"                    => "OtherSv",
    "E86_WRKRID"                     => "WrkrID",
    "E87_SUPRVID"                    => "SuprvID",
    "E88_PER1ID"                     => "Per1ID",
    "E89_PER1REL"                    => "Per1Rel",
    "E90_PER1PRNT"                   => "Per1Prnt",
    "E91_PER1CR"                     => "Per1Cr",
    "E92_PER1AGE"                    => "Per1Age",
    "E93_PER1SEX"                    => "Per1Sex",
    "E94_P1RACAI"                    => "P1RacAI",
    "E95_P1RACAS"                    => "P1RacAs",
    "E96_P1RACBL"                    => "P1RacBl",
    "E97_P1RACNH"                    => "P1RacNH",
    "E98_P1RACWH"                    => "P1RacWh",
    "E99_P1RACUD"                    => "P1RacUd",
    "E100_PER1ETHN"                  => "Per1Ethn",
    "E101_PER1MIL"                   => "Per1Mil",
    "E102_PER1PIOR"                  => "Per1Pior",
    "E103_PER1MAL1"                  => "Per1Mal1",
    "E104_PER1MAL2"                  => "Per1Mal2",
    "E105_PER1MAL3"                  => "Per1Mal3",
    "E106_PER1MAL4"                  => "Per1Mal4",
    "E107_PER2ID"                    => "Per2ID",
    "E108_PER2REL"                   => "Per2Rel",
    "E109_PER2PRNT"                  => "Per2Prnt",
    "E110_PER2CR"                    => "Per2Cr",
    "E111_PER2AGE"                   => "Per2Age",
    "E112_PER2SEX"                   => "Per2Sex",
    "E113_P2RACAI"                   => "P2RacAI",
    "E114_P2RACAS"                   => "P2RacAs",
    "E115_P2RACBL"                   => "P2RacBl",
    "E116_P2RACNH"                   => "P2RacNH",
    "E117_P2RACWH"                   => "P2RacWh",
    "E118_P2RACUD"                   => "P2RacUd",
    "E119_PER2ETHN"                  => "Per2Ethn",
    "E120_PER2MIL"                   => "Per2Mil",
    "E121_PER2PIOR"                  => "Per2Pior",
    "E122_PER2MAL1"                  => "Per2Mal1",
    "E123_PER2MAL2"                  => "Per2Mal2",
    "E124_PER2MAL3"                  => "Per2Mal3",
    "E125_PER2MAL4"                  => "Per2Mal4",
    "E126_PER3ID"                    => "Per3ID",
    "E127_PER3REL"                   => "Per3Rel",
    "E128_PER3PRNT"                  => "Per3Prnt",
    "E129_PER3CR"                    => "Per3Cr",
    "E130_PER3AGE"                   => "Per3Age",
    "E131_PER3SEX"                   => "Per3Sex",
    "E132_P3RACAI"                   => "P3RacAI",
    "E133_P3RACAS"                   => "P3RacAs",
    "E134_P3RACBL"                   => "P3RacBl",
    "E135_P3RACNH"                   => "P3RacNH",
    "E136_P3RACWH"                   => "P3RacWh",
    "E137_P3RACUD"                   => "P3RacUd",
    "E138_PER3ETHN"                  => "Per3Ethn",
    "E139_PER3MIL"                   => "Per3Mil",
    "E140_PER3PIOR"                  => "Per3Pior",
    "E141_PER3MAL1"                  => "Per3Mal1",
    "E142_PER3MAL2"                  => "Per3Mal2",
    "E143_PER3MAL3"                  => "Per3Mal3",
    "E144_PER3MAL4"                  => "Per3Mal4",
    "E145_AFCARSID"                  => "AFCARSID",
    "E146_INCIDDT"                   => "IncidDt",
    "E147_RPTTM"                     => "RptTm",
    "E148_INVSTRTM"                  => "InvstrTm",
    "E149_DEATHDT"                   => "DeathDt",
    "E150_FCDCHDT"                   => "FCDchDt",
    "E151_SAFECARE"                  => "PlnsFCr",
    "E152_CARAREF"                   => "RefrCARA"
);

sub remap {
    my ( $rec, $field, $map ) = @_;
    if ( !exists $map->{ lc( $rec->{$field} ) } ) {
        warn "No mapping for $field => $rec->{$field} in map";
        return;
    }
    $rec->{$field} = $map->{ lc( $rec->{$field} ) };
}

my @dates = qw(
    DOB
    InvDate
    ServDate
    RmvDate
    PetDate
    RptDt
    RpDispDt
    FCDchDt
);

my %report_source = (
    "n/a"                                                   => "",
    "unknown"                                               => 99,
    "social services personnel"                             => 1,
    "medical personnel"                                     => 2,
    "mental health personnel"                               => 3,
    "legal, law enforcement, or criminal justice personnel" => 4,
    "education personnel"                                   => 5,
    "child daycare provider"                                => 6,
    "substitute care provider"                              => 7,
    "alleged victim"                                        => 8,
    "parent"                                                => 9,
    "other relative"                                        => 10,
    "friends/neighbors"                                     => 11,
    "friends/neighbours"                                    => 11,
    "alleged perpetrator"                                   => 12,
    "anonymous reporter"                                    => 13,
    "other"                                                 => 88,
    "unknown or missing"                                    => 99,
);

my %report_disposition = (
    "n/a"                                                  => "",
    "substantiated"                                        => 1,
    "indicated or reason to suspect"                       => 2,
    "alternative response victim"                          => 3,
    "alternative responsive victim"                        => 3,
    "alternative response nonvictim"                       => 4,
    "alternative responsive nonvictim"                     => 4,
    "unsubstantiated"                                      => 5,
    "unsubstantiated due to intentionally false reporting" => 6,
    "closed-no finding"                                    => 7,
    "other"                                                => 88,
    "unknown or missing"                                   => 99,
    "unknown"                                              => 99,
);

my %notifications = (
    "n/a"                => "",
    "none"               => 1,
    "police/prosecutor"  => 2,
    "licensing agency"   => 3,
    "both"               => 4,
    "other"              => 8,
    "unknown"            => 9,
    "unknown or missing" => 9,
);

my %yes_no = (
    ""    => "",
    "0"   => 0,
    "1"   => 1,
    "no"  => 0,
    "yes" => 1,
);

my %sex = (
    "male"    => 1,
    "n/a"     => "",
    "female"  => 2,
    "unknown" => 9,
);

my @yes_no_unable = qw(
    ChRacAI
    ChRacAs
    ChRacBl
    ChRacNH
    ChRacWh
    ChRacUD
    P1RacAI
    P1RacAs
    P1RacBl
    P1RacNH
    P1RacWh
    P1RacUd
    P2RacAI
    P2RacAs
    P2RacBl
    P2RacNH
    P2RacWh
    P2RacUd
    P3RacAI
    P3RacAs
    P3RacBl
    P3RacNH
    P3RacWh
    P3RacUd
    ChMil
    ChPrior
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
    FamSup
    FamPres
    FosterCr
    JuvPet
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
    Per1Cr
    Per1Mil
    Per1Pior
    Per1Mal1
    Per1Mal2
    Per1Mal3
    Per1Mal4
    Per2Cr
    Per2Mil
    Per2Pior
    Per2Mal1
    Per2Mal2
    Per2Mal3
    Per2Mal4
    Per3Cr
    Per3Mil
    Per3Pior
    Per3Mal1
    Per3Mal2
    Per3Mal3
    Per3Mal4
    PlnsFCr
    RefrCARA
);

my @ethnicity = qw(
    CEthn
    Per1Ethn
    Per2Ethn
    Per3Ethn
);

my %living = (
    "n/a"     => "",
    "married" => 1,

    "non-parent relative caregiverhousehold(includes relative foster care)"
        => 10,
    "non-relative caregiver household(includes non-relative foster care)" =>
        11,
    "group home or residential treatment settling"      => 12,
    "other settling(hospital, secure facilities, etc.)" => 88,
    "unknown"                                           => 99,
);

my @maltreatment_fields = qw(
    ChMal1
    ChMal2
    ChMal3
    ChMal4
);

my %maltreatments = (
    "n/a"                                     => "",
    "physical abuse"                          => 1,
    "neglect or deprivation of necessities"   => 2,
    "medical neglect"                         => 3,
    "sexual abuse"                            => 4,
    "psychological or emotional maltreatment" => 5,
    "no alleged maltreatment"                 => 6,
    "sex trafficking"                         => 7,
    "other"                                   => 8,
    "unknown"                                 => 9,
);

my @maltreatment_disposition_fields = qw(
    Mal1Lev
    Mal2Lev
    Mal3Lev
    Mal4Lev
);

my %maltreatment_dispositions = (
    "n/a"                                        => "",
    "substantiated"                              => 1,
    "indicated or reason to suspect"             => 2,
    "alternative responsive victim"              => 3,
    "alternative responsive nonvictim"           => 4,
    "unsubstantiated"                            => 5,
    "unsubstantiated-intentionally false report" => 6,
    "closed-no finding"                          => 7,
    "no alleged maltreatment"                    => 8,
    "other"                                      => 88,
    "unknown"                                    => 99,
);

my %rels = (
    "n/a"                                               => "",
    "1"                                                 => 1,
    "parent"                                            => 1,
    "2"                                                 => 2,
    "other relative (non-foster parent)"                => 2,
    "other relative (non foster parent)"                => 2,
    "3"                                                 => 3,
    "relative foster parent"                            => 3,
    "nonrelative foster parent"                         => 4,
    "group home or residential facility staff"          => 5,
    "child daycare provider"                            => 6,
    "unmarried partner of parent"                       => 7,
    "unmarried partner or parent"                       => 7,
    "legal guardian"                                    => 8,
    "9"                                                 => 9,
    "other professionals"                               => 9,
    "friends or neighbors"                              => 10,
    "foster parent-relationship unknown or unspecified" => 33,
    "other"                                             => 88,
    "unknown or missing"                                => 99,
    "unknown"                                           => 99,
);

my %parents = (
    "n/a"                => "",
    "biological parent"  => 1,
    "step-parent"        => 2,
    "adoptive parent"    => 3,
    "unknown or missing" => 9,
    "unknown"            => 9,
);

my %warned = ();

sub norm_rec {
    my ( $file, $rec ) = @_;

    my $normed = {};
    for my $k ( keys %$rec ) {
        if ( !exists $MAP{$k} ) {
            warn "$file: Key $k not in MAP" unless $warned{$file}->{$k}++;
            $normed->{$k} = $rec->{$k};
            next;
        }
        next if $MAP{$k} eq "";
        $normed->{ $MAP{$k} } = $rec->{$k};
    }

    for my $f (@dates) {
        $normed->{$f} = parse_date_mdy( $normed->{$f} );
    }

    remap( $normed, "RptSrc",  \%report_source );
    remap( $normed, "RptDisp", \%report_disposition );
    remap( $normed, "Notifs",  \%notifications );
    remap( $normed, "ChSex",   \%sex );
    remap( $normed, "Per1Sex", \%sex );
    remap( $normed, "Per2Sex", \%sex );
    remap( $normed, "Per3Sex", \%sex );
    remap( $normed, "ChLvng",  \%living );
    for my $f (@maltreatment_fields) {
        remap( $normed, $f, \%maltreatments );
    }
    for my $f (@maltreatment_disposition_fields) {
        remap( $normed, $f, \%maltreatment_dispositions );
    }
    for my $n ( ( 1, 2, 3 ) ) {
        remap( $normed, "Per${n}Rel",  \%rels );
        remap( $normed, "Per${n}Prnt", \%parents );
    }

    for my $f (@yes_no_unable) {
        if ( !$normed->{$f} ) { warn "$f undefined"; next; }
        if ( lc( $normed->{$f} ) eq "not applicable" ) { $normed->{$f} = "" }
        if ( lc( $normed->{$f} ) eq "n/a" )            { $normed->{$f} = "" }
        if ( lc( $normed->{$f} ) =~ /yes\b/ )          { $normed->{$f} = 1 }
        if ( lc( $normed->{$f} ) =~ /no\b/ )           { $normed->{$f} = 2 }
        if ( lc( $normed->{$f} ) =~ /determine/ )      { $normed->{$f} = 3 }
        if ( lc( $normed->{$f} ) =~ /unknown/ )        { $normed->{$f} = 9 }
    }

    for my $f (@ethnicity) {
        if ( !$normed->{$f} ) { warn "$f undefined"; next; }
        if ( lc( $normed->{$f} ) eq "n/a" ) { $normed->{$f} = "" }
        if ( lc( $normed->{$f} ) eq "not hispanic or latino" ) {
            $normed->{$f} = 2;
        }
        if ( lc( $normed->{$f} ) eq "hispanic or latino" ) {
            $normed->{$f} = 1;
        }
        if ( lc( $normed->{$f} ) =~ /determine/ ) { $normed->{$f} = 3 }
        if ( lc( $normed->{$f} ) =~ /unknown/ )   { $normed->{$f} = 9 }

    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    return $normed;
}

for my $json_file (@ARGV) {
    my $buf      = read_json($json_file);
    my $csv_file = $json_file;
    $csv_file =~ s/\.json$/-norm.csv/;
    my $csv
        = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
    $csv->column_names( \@csv_header );
    open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
    $csv->print( $fh, \@csv_header );

    for my $rec (@$buf) {
        my $normed = norm_rec( $json_file, $rec );

        $csv->print_hr( $fh, $normed );
    }

    close $fh;
}
