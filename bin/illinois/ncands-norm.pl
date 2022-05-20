#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_mdy_cat read_json trim );

my $ncands_fields = csv(
    in      => "$FindBin::Bin/../../eval/ncands-vars.csv",
    headers => "auto"
);
my @csv_header = map { $_->{name} } @$ncands_fields;
push @csv_header, "DOB";    # unofficial

my %MAP = (
    "SUBYR"                  => "SubYr",
    "STATERR"                => "StaTerr",
    "RPTID"                  => "RptID",
    "CHID"                   => "ChID",
    "RPTCNTY"                => "RptFIPS",
    "RPTDT"                  => "RptDt",
    "INVDATE"                => "InvDate",
    "RPTSRC"                 => "RptSrc",
    "RPTDISP"                => "RptDisp",
    "RPTDISDT"               => "RpDispDt",
    "NOTIFS"                 => "Notifs",
    "CHAGE"                  => "ChAge",
    "CHBATE"                 => "DOB",
    "CHDOB"                  => "DOB",
    "CHSEX"                  => "ChSex",
    "CHRACAI"                => "ChRacAI",
    "CHRACAS"                => "ChRacAs",
    "CHRACBL"                => "ChRacBl",
    "CHRACNH"                => "ChRacNH",
    "CHRACWH"                => "ChRacWh",
    "CHRACUD"                => "ChRacUD",
    "CHETHN"                 => "CEthn",
    "CHCNTY"                 => "ChCnty",
    "CHLVNG"                 => "ChLvng",
    "CHMIL"                  => "ChMil",
    "CHPRIOR"                => "ChPrior",
    "CHMAL1"                 => "ChMal1",
    "MAL1EV"                 => "Mal1Lev",
    "MAL1LEV"                => "Mal1Lev",
    "CHMAL2"                 => "ChMal2",
    "MAL2EV"                 => "Mal2Lev",
    "MAL2LEV"                => "Mal2Lev",
    "CHMAL3"                 => "ChMal3",
    "MAL3LEV"                => "Mal3Lev",
    "MAL3EV"                 => "Mal3Lev",
    "CHMAL4"                 => "ChMal4",
    "MAL4LEV"                => "Mal4Lev",
    "MAL4EV"                 => "Mal4Lev",
    "MALDEATH"               => "MalDeath",
    "CDALC"                  => "CdAlc",
    "CDDRUG"                 => "CdDrug",
    "CDRTRD"                 => "CdRtrd",
    "CDEMOTNL"               => "CdEmotnl",
    "CDVISUAL"               => "CdVisual",
    "CDLEARN"                => "CdLearn",
    "CDPHYS"                 => "CdPhys",
    "CDBEHAV"                => "CdBehav",
    "CDMEDICL"               => "CdMedicl",
    "FCALC"                  => "FCAlc",
    "FCDRUG"                 => "FCDrug",
    "FCRTRD"                 => "FCRtrd",
    "FCEMOTNL"               => "FCEmotnl",
    "FCVISUAL"               => "FCVisual",
    "FCLEARN"                => "FCLearn",
    "FCDLEARN"               => "FCLearn",
    "FCPHYS"                 => "FCPhys",
    "FCMEDICL"               => "FCMedicl",
    "FCVIOL"                 => "FCViol",
    "FCHOUSE"                => "FCHouse",
    "FCMONEY"                => "FCMoney",
    "FCPUBLIC"               => "FCPublic",
    "POSTSERV"               => "PostServ",
    "SERVDATE"               => "ServDate",
    "FAMSUP"                 => "FamSup",
    "FAMPRES"                => "FamPres",
    "FOSTERCR"               => "FosterCr",
    "RMVDATE"                => "RmvDate",
    "JUVPET"                 => "JuvPet",
    "PETDATE"                => "PetDate",
    "COCHREP"                => "CoChRep",
    "ADOPT"                  => "Adopt",
    "CASEMANG"               => "CaseMang",
    "COUNSEL"                => "Counsel",
    "DAYCARE"                => "Daycare",
    "EDUCATN"                => "Educatn",
    "EMPLOY"                 => "Employ",
    "FAMPLAN"                => "FamPlan",
    "HEALTH"                 => "Health",
    "HOMEBASE"               => "Homebase",
    "HOUSING"                => "Housing",
    "TRANSLIV"               => "TransLiv",
    "INFOREF"                => "InfoRef",
    "LEGAL"                  => "Legal",
    "MENTHLTH"               => "MentHlth",
    "PREGPAR"                => "PregPar",
    "RESPITE"                => "Respite",
    "SSDISABL"               => "SSDisabl",
    "SSDELINQ"               => "SSDelinq",
    "SUBABUSE"               => "SubAbuse",
    "TRANSPRT"               => "Transprt",
    "OTHERSV"                => "OtherSv",
    "WRKRID"                 => "WrkrID",
    "SUPRVID"                => "SuprvID",
    "PER1ID"                 => "Per1ID",
    "PER1REL"                => "Per1Rel",
    "PER1PRNT"               => "Per1Prnt",
    "PER1CR"                 => "Per1Cr",
    "PER1AGE"                => "Per1Age",
    "PER1SEX"                => "Per1Sex",
    "P1RACAI"                => "P1RacAI",
    "P1RACAS"                => "P1RacAs",
    "P1RACBL"                => "P1RacBl",
    "P1RACNH"                => "P1RacNH",
    "P1RACWH"                => "P1RacWh",
    "P1RACUD"                => "P1RacUD",
    "PER1ETHN"               => "Per1Ethn",
    "PER1MIL"                => "Per1Mil",
    "PER1PIOR"               => "Per1Pior",
    "PER1MAL1"               => "Per1Mal1",
    "PER1MAL2"               => "Per1Mal2",
    "PER1MAL3"               => "Per1Mal3",
    "PER1MAL4"               => "Per1Mal4",
    "PER2ID"                 => "Per2ID",
    "PER2REL"                => "Per2Rel",
    "PER2PRNT"               => "Per2Prnt",
    "PER2CR"                 => "Per2Cr",
    "PER2AGE"                => "Per2Age",
    "PER2SEX"                => "Per2Sex",
    "P2RACAI"                => "P2RacAI",
    "P2RACAS"                => "P2RacAs",
    "P2RACBL"                => "P2RacBl",
    "P2RACNH"                => "P2RacNH",
    "P2RACWH"                => "P2RacWh",
    "P2RACUD"                => "P2RacUD",
    "PER2ETHN"               => "Per2Ethn",
    "PER2MIL"                => "Per2Mil",
    "PER2PIOR"               => "Per2Pior",
    "PER2MAL1"               => "Per2Mal1",
    "PER2MAL2"               => "Per2Mal2",
    "PER2MAL3"               => "Per2Mal3",
    "PER2MAL4"               => "Per2Mal4",
    "PER3ID"                 => "Per3ID",
    "PER3REL"                => "Per3Rel",
    "PER3PRNT"               => "Per3Prnt",
    "PER3CR"                 => "Per3Cr",
    "PER3AGE"                => "Per3Age",
    "PER3SEX"                => "Per3Sex",
    "P3RACAI"                => "P3RacAI",
    "P3RACAS"                => "P3RacAs",
    "P3RACBL"                => "P3RacBl",
    "P3RACNH"                => "P3RacNH",
    "P3RACWH"                => "P3RacWh",
    "P3RACUD"                => "P3RacUD",
    "PER3ETHN"               => "Per3Ethn",
    "PER3MIL"                => "Per3Mil",
    "PER3PIOR"               => "Per3Pior",
    "PER3MAL1"               => "Per3Mal1",
    "PER3MAL2"               => "Per3Mal2",
    "PER3MAL3"               => "Per3Mal3",
    "PER3MAL4"               => "Per3Mal4",
    "AFCARSID"               => "AFCARSID",
    "INCIDDT"                => "IncidDt",
    "RPTTM"                  => "RptTm",
    "INVSTRTM"               => "InvstrTm",
    "DEATHDT"                => "DeathDt",
    "FCDCHDT"                => "FCDchDt",
    "ID_INVST"               => "",
    "ID_INVST_SUBJ"          => "",
    "ID_INVST_CASE"          => "",
    "ID_SCR_SEQ"             => "",
    "chid_id_pers"           => "",
    "DT_INVST_RPT"           => "",
    "DT_FIND"                => "",
    "cd_find"                => "",
    "DT_OF_BIRTH"            => "",
    "CYCIS_SERV_DATE"        => "",
    "CYCIS_RMVL_DATE"        => "",
    "CYCIS_PET_DATE"         => "",
    "WRKRID_id_pers"         => "",
    "SUPRVID_id_pers"        => "",
    "PER1ID_id_pers"         => "",
    "PER2ID_id_pers"         => "",
    "PER3ID_id_pers"         => "",
    "AFCARSID_cycis_case_id" => "",
    "DT_INCDT"               => "",
    "TM_INVST_RPT"           => "",
    "DT_DCSD"                => "",
    "LIVAR_END_DT"           => "",
    "id_org_ent"             => "",
);

# warn just once per file
my %warned = ();

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

sub norm_rec {
    my ( $file, $rec ) = @_;

    my $normed = {};
    for my $k ( keys %$rec ) {
        if ( !exists $MAP{$k} ) {
            warn "$file: Key $k not in MAP" unless $warned{$file}->{$k}++;
            $normed->{$k} = $rec->{$k};
            next;
        }

        # skip empties
        if ( $MAP{$k} eq "" ) {
            next;
        }
        if ( exists $normed->{ $MAP{$k} } ) {
            warn "$file: Duplicate mappings to same target field $MAP{$k}";
            next;
        }
        $normed->{ $MAP{$k} } = $rec->{$k};
    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    for my $f (@dates) {
        $normed->{$f} = parse_date_mdy_cat( $normed->{$f} );
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

