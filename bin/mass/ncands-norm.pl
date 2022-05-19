#!/usr/bin/env perl
use strict;
use warnings;

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
    "E22_CHCNTY"                     => "",
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
    "E45_FCDRUG"                     => "LCDrug",
    "E46_FCRTRD"                     => "LCRtrd",
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
    "E86_WRKRID"                     => "",
    "E87_SUPRVID"                    => "",
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
    "E146_INCIDDT"                   => "",
    "E147_RPTTM"                     => "",
    "E148_INVSTRTM"                  => "",
    "E149_DEATHDT"                   => "",
    "E150_FCDCHDT"                   => "FCDchDt",
    "E151_SAFECARE"                  => "PlnsFCr",
    "E152_CARAREF"                   => "RefrCARA"
);
