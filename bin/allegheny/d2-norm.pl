#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_abbrev read_json trim );

my $usage = "$0 afile bfile cfile";

my %MAP = ();

# load allegation mapping

my %allegation_codes = (
    "n/a"                                     => "",
    "physical abuse"                          => 1,
    "neglect or deprivation of necessities"   => 2,
    "medical neglect"                         => 3,
    "sexual abuse"                            => 4,
    "psychological or emotional maltreatment" => 5,
    "no alleged maltreatment"                 => 6,
    "sex trafficking"                         => 7,
    "other"                                   => 8,
    "unknown or missing"                      => 9,
);

sub remap {
    my ( $rec, $field, $map ) = @_;
    if ( !exists $rec->{$field} ) {
        warn "field $field not in record: " . dump($rec);
        return;
    }
    if ( !exists $map->{ lc( $rec->{$field} ) } ) {
        warn "No mapping for $field => $rec->{$field} in map";
        return;
    }
    $rec->{$field} = $map->{ lc( $rec->{$field} ) };
}

my @dates = qw(
    contact_date
);

my %warned = ();

sub norm_rec {
    my ( $file, $rec ) = @_;

    my $normed = {};
    for my $k ( keys %$rec ) {
        next unless $k;
        if ( !exists $MAP{$k} ) {
            warn "$file: Key $k not in MAP" unless $warned{$file}->{$k}++;
            $normed->{$k} = $rec->{$k};
            next;
        }
        next if $MAP{$k} eq "";
        $normed->{ $MAP{$k} } = $rec->{$k};
    }

    for my $f (@dates) {
        $normed->{$f} = parse_date_abbrev( $normed->{$f} );
    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    return $normed;
}

my $a_file = shift or die $usage;
my $b_file = shift or die $usage;
my $c_file = shift or die $usage;

my $a_recs = read_json($a_file);
my $b_recs = read_json($b_file);
my $c_recs = read_json($c_file);

# build tree joined by REFER_ID,
# then normalize as a single record
my %recs;

for my $a (@$a_recs) {
    $recs{ $a->{REFER_ID} } ||= { a => [], b => [], c => [] };
    push @{ $recs{ $a->{REFER_ID} }->{a} }, $a;
}

for my $b (@$b_recs) {
    $recs{ $b->{REFER_ID} } ||= { b => [], c => [] };
    push @{ $recs{ $b->{REFER_ID} }->{b} }, $b;
}

for my $c (@$c_recs) {
    $recs{ $c->{REFER_ID} } ||= { c => [] };
    push @{ $recs{ $c->{REFER_ID} }->{c} }, $c;
}

# first debug
my ( $ref_id, $rec ) = each %recs;

dump $rec;

exit;

# NCANDS has children + reports
# the equivalent here is A == report
# and B == child (or adult)
# we output one line per-child-per-report
# "episode" == "report"

# a fields
# REFER_ID,REF_TYPE,CPS,GPS,INTAKE_DT,CAS_ID,CAS_OPN_DT,LAST_CLOSE_DT,SERVICE_ACCEPT_DT,CALL_SCRN_CODE,SERVICE_DECISION_CODE
# REFER_ID	unique identifier per referral
# REF_TYPE	CPS or GPS
# CPS	Child Protective Services (CPS) and General Protective Services (GPS) are attached at the allegation level of a child welfare referral. CPS refers to allegations of child abuse. GPS allegations are generally considered to involve “non-serious injury or neglect” (e.g., inadequate shelter, truancy, inappropriate discipline, abandonment or other problems that threaten a child’s opportunity for healthy growth and development). Some referrals have both types of allegations, but typically a referral only has CPS or only has GPS allegations.
# GPS
# INTAKE_DT	Date of referral made
# CAS_ID	Unique identifer per family.  Note, only families with a CYF case receive this identifier.
# CAS_OPN_DT	Case opening date
# LAST_CLOSE_DT	Case closing date
# SERVICE_ACCEPT_DT	Following an investigation, date the family is found to have sufficient needs to warrant support and/or supervision from Children, Youth, and Families (CYF).
# CALL_SCRN_CODE	0= 'Screen Out', indicating that the initial referral did not rise to level of needing further investigation. 1 = 'Screen In', indicating an investigation into allegations made during the referral will begin.  2 = 'Active', indicating the family about whom the referral was made already has an open CYF case.
# SERVICE_DECISION_CODE	0 = 'Do not accept for services', indicating the investigation did not yield sufficient concern to warrant further support and/or services from CYF. 1 = 'Accept for services', indicating the investigation yielded sufficient cause for concern to warrant continued supervisiop, services, and/or support from CYF.  1 indicates the family will have a case open. 2 = 'Active family', indicating that the family is already active with CYF (receiving services, supervision, and/or support from CYF).
# b fields
# REFER_ID,CL_ID,INTAKE_DT,ALL_CHILD,APRP,AVSC,PARENT,CARETAKER,LEG_GUARD,HSHLD_MBR,AGE_AT_REFER,GENDER,RACE_GROUP,STATE_MCI_ID
# Fields	Definition
# REFER_ID	unique identifier per referral
# CL_ID	unique identifier per client
# INTAKE_DT	date of referral
# ALL_CHILD	Role on referral
# APRP	role on referral: alledged perpetrator
# AVSC	role on referral: alledged victim
# PARENT	Role on referral
# CARETAKER	Role on referral
# LEG_GUARD	Role on referral: legal guardian
# HSHLD_MBR	Role on referral: household member
# AGE_AT_REFER	Age at the intake date
# GENDER
# RACE_GROUP
# STATE_MCI_ID	Child State ID/ AFCARS ID
# c fields
# REFER_ID,CL_ID,CAS_ID,ABS_TYPE

my @csv_header = qw(
    ref_id
    client_id
    intake_date
    child
    alleged_perp
    alleged_victim
    parent
    caretaker
    legal_guardian
    household_member
    age
    gender
    race
    state_mci_id
    ref_type
    case_id
    case_opened_date
    case_closed_date
    service_accept_date
    call_screen_code
    service_decision_code
    allegation_code
);

my $header   = [@csv_header];
my $csv_file = $a_file;
$csv_file =~ s,/.+?\.json,data-set-2-norm.csv,;
my $csv = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
$csv->column_names($header);
open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
$csv->print( $fh, $header );

for my $ref_id ( keys %recs ) {
    my $r = norm_rec( $recs{$ref_id} );
    $csv->print_hr( $fh, $r );
    $fh->flush;
}

close $fh;
