#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_abbrev read_json trim );

# A Case definitions
# ASGN_ID
# CAS_ID	CYF Case ID (5 digits) or Referral ID (6 digits)
# OPEN_DATE	If a CYF case, the most recent date the case opened; if a referral, the referral intake date
# MO_YEAR
# CAS_TYP	refers to Family Services or Referral
# REGIONAL_OFFICE	regional office handling the investigation and/or case
# WORKER_ID	A unique ID for the caseworker
# CASEWORKER_NAME	The caseworker's name
# UNIT_NAME	The name of the supervisory unit
# SUPERVISOR_NAME	The supervisor's name
# LAST_ASGN_STRT_DT	The beginning date of the most recent "Family Assignment" period
# LAST_ASGN_END_DT	The end date (if applicable) of the most recent "Family Assignment" period
# IPV_SVCREFS	Binary variable for any IPV-related non-placement service referrals
# MIN_IPV_SVCREFS	Minimum date of any IPV-related non-placement service referrals
# MAX_IPV_SVCREFS	Maximum date of any IPV-related non-placement service referrals
# IPV_INTAKEREFS	Binary variable for any CYF referrals with IPV allegation(s) ("Domestic Violence" allegation type)
# MIN_IPV_INTAKEREFS	Minimum date of any CYF referrals with IPV allegation(s) ("Domestic Violence" allegation type)
# MAX_IPV_INTAKEREFS	Maximum date of any CYF referrals with IPV allegation(s) ("Domestic Violence" allegation type)
# IPV_FAST_RESPONSES	Binary variable for any IPV indicated on a FAST assessment
# MIN_IPV_FASTRESP	Minimum date of any IPV indicated on a FAST assessment
# MAX_IPV_FASTRESP	Maximum date of any IPV indicated on a FAST assessment
# IPV_CHLDRMVL_CASES	Binary variable for any child removed from the home for a "Domestic Violence" removal reason
# MIN_IPV_CHLDRMVL	Minimum date of any child removed from the home for a "Domestic Violence" removal reason
# MAX_IPV_CHLDRMVL	Maximum date of any child removed from the home for a "Domestic Violence" removal reason
# IPV_TOTAL	Binary for if any of the previous IPV binaries are triggered
# MIN_IPV_EVER	Minimum date of any IPV recognition above
# MAX_IPV_EVER	Maximum date of any IPV recognition above
# IPV_TOTAL_SANS_INTAKE	without intake / CYF referral allegation
# MIN_IPV_SANS_INTAKE	without intake / CYF referral allegation
# MAX_IPV_SANS_INTAKE	without intake / CYF referral allegation
# MIN_FES_CONTACT	min date of Fatherhood Engagement Specialist
# MAX_FES_CONTACT	max date of Fatherhood Engagement Specialist
# FES_BIN	Fatherhood engagement specialist
# FES_CONTACTS_EVER	FES contacts
# BIP_MIN_DT	min date of Batters Intervention Program
# BIP_MAX_DT	max date of Batterers Intervention Program
# BIP_NPS_EVER	BIP ever
# IPV_NPS_MIN_DT	min date of non placement services (NPS) IPV
# IPV_NPS_MAX_DT	max date of non placement services (NPS) IPV
# IPV_NPS_EVER	IPV nonplacement services ever
#
# B Individual definitions
# ENTITY_ID	family level identifier: either a case or a referral
# CAS_OR_REF_TYPE	This identifies whether the entity id is a case or a referral or juvenile justice
# Family Services	CYF family case
# JPO	Juvenile justice
# Resumption	CYF family case when a child leaves foster care, and comes back as an adult
# GPS	CYF Referral
# CPS, GPS	CYF Referral
# CPS	CYF Referral
# NONE	CYF Referral
# GPS, NONE	CYF Referral
# CL_ID	individual client level identifier
# MCI_ID	individual client level identifier
# Age at INVLV_STRT_DT	age
# SEX	sex
# RACE_GROUP	race
# REF_CHILD	only applicable for referrals - role of individual
# REF_VICTIM	only applicable for referrals - role of individual
# REF_PERP	only applicable for referrals - role of individual
# CYF_ROLE	role
# INVLV_STRT_DT	CYF involvement start date
# INVLV_END_DT	CYF involvement end date
# Client on IPV Case

my %MAP = (
    CAS_ID          => 'case_id',
    OPEN_DATE       => 'case_date',
    # CAS_TYPE        => 'case_type',
    REGIONAL_OFFICE => 'region_name',
    UNIT_NAME       => 'area_name',
    CL_ID           => 'state_child_id',
    MCI_ID          => 'federal_child_id',
    CAS_OR_REF_TYPE => 'case_type',
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
    case_date
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

my @csv_header = qw(
    federal_child_id
    state_child_id
    case_id
    case_date
    case_type
    region_name
    area_name
);

my $usage      = "$0 cases.json individuals.json";
my $case_file  = shift(@ARGV) or die $usage;
my $indiv_file = shift(@ARGV) or die $usage;

my $cases_buf  = read_json($case_file);
my $indivs_buf = read_json($indiv_file);

my $header   = [@csv_header];
my $csv_file = $case_file;
$csv_file =~ s,^(.+)/Data-Set.*\.json$,$1/dv-data-set-3-norm.csv,;
my $csv = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
$csv->column_names($header);
open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
$csv->print( $fh, $header );

# build cases meta to populate each individual
# FK is CAS_ID -> ENTITY_ID
my %cases = ();
for my $c (@$cases_buf) {
    $cases{ $c->{CAS_ID} } = $c;
}
for my $rec (@$indivs_buf) {
    my $case = $cases{ $rec->{ENTITY_ID} }
        or die "No case for $rec->{ENTITY_ID}";
    my %merged = ( %$case, %$rec );
    if (! $merged{'Age at INVLV_STRT_DT'}) {
        print "No age: " . dump( \%merged ) . "\n";
    } else {
        print "Age $merged{'Age at INVLV_STRT_DT'}\n";
    }
    my $normed = norm_rec( $case_file, \%merged );
    $csv->print_hr( $fh, $normed );
    $fh->flush;
}

close $fh;
