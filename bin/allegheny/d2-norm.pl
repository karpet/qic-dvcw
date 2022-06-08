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

my $MAX_PERPS = 10;

# load allegation mapping
my $allegation_mapping = csv(
    in      => "$FindBin::Bin/../../eval/allegheny-allegation-mapping.csv",
    headers => "auto"
);
my %allegation_map = map { $_->{allegation} => $_ } @$allegation_mapping;

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

sub get_allegation_code {
    my $abs       = shift            or return "";
    my $orig_text = $abs->{ABS_TYPE} or return "";

    # ambiguous original values
    return 9 if $orig_text eq 'Causing';
    return 9 if $orig_text eq 'Contributing To';
    return 9 if $orig_text eq 'Exposing';

    if ( !exists $allegation_map{$orig_text} ) {
        die "Missing allegation map for '$orig_text'";
    }
    my $name = $allegation_map{$orig_text}->{ba}
        || $allegation_map{$orig_text}->{njk};
    if ( !$name ) {
        die "No allegation map for '$orig_text'";
    }
    if ( !exists $allegation_codes{$name} ) {
        die "No allegation code for '$name'";
    }
    return $allegation_codes{$name};
}

my %sex = (
    ""        => "",
    "male"    => 1,
    "n/a"     => "",
    "female"  => 2,
    "unknown" => 9,
);

sub remap {
    my ( $rec, $field, $map ) = @_;
    if ( !exists $rec->{$field} ) {
        warn "field $field not in record: " . dump($rec);
        return;
    }
    if ( !defined $rec->{$field} ) {
        return $map->{""};
    }
    if ( !exists $map->{ lc( $rec->{$field} ) } ) {
        warn "No mapping for $field => $rec->{$field} in map";
        return;
    }
    $rec->{$field} = $map->{ lc( $rec->{$field} ) };
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
#my ( $ref_id, $rec ) = each %recs;
#dump $rec;
#exit;

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

sub get_role {
    my $perp = shift;

    # TODO can more than one be true?
    return 'parent'    if $perp->{PARENT};
    return 'caretaker' if $perp->{CARETAKER};
    return 'guardian'  if $perp->{LEG_GUARD};
    return 'household' if $perp->{HSHLD_MBR};
    return '';
}

sub get_perps {
    my $people = shift;
    my $victim = shift;
    my @perps;
    my %uniq;

    #warn '=' x 80;
    for my $p (@$people) {
        if ( $p->{APRP} ) {

            #warn "trying to match " . dump([$victim, $p]);
            push @perps,
                {
                id   => $p->{CL_ID},
                sex  => $p->{GENDER},
                role => get_role($p),
                r    => $p
                };
        }
    }
    return [ grep { !$uniq{ $_->{id} }++ } @perps ];
}

sub build_rows {
    my $tree        = shift;
    my $case        = $tree->{a}->[0];
    my $people      = $tree->{b};
    my $allegations = $tree->{c};
    my @rows;
    for my $p (@$people) {
        if ( $p->{ALL_CHILD} and $p->{AVSC} ) {
            my $r = {
                ref_id           => $p->{REFER_ID},
                ref_type         => $case->{REF_TYPE},
                client_id        => $p->{CL_ID},
                intake_date      => parse_date_abbrev( $case->{INTAKE_DT} ),
                age              => $p->{AGE_AT_REFER},
                sex              => $p->{GENDER},
                race             => $p->{RACE_GROUP},
                afcars_id        => $p->{STATE_MCI_ID},
                case_id          => $case->{CAS_ID},
                case_opened_date => parse_date_abbrev( $case->{CAS_OPN_DT} ),
                case_closed_date =>
                    parse_date_abbrev( $case->{LAST_CLOSE_DT} ),
                service_accept_date =>
                    parse_date_abbrev( $case->{SERVICE_ACCEPT_DT} ),
                call_screen_code      => $case->{CALL_SCRN_CODE},
                service_decision_code => $case->{SERVICE_DECISION_CODE},
                allegation_code       => get_allegation_code(
                    grep { $_->{CL_ID} eq $p->{CL_ID} } @$allegations
                ),
            };
            remap( $r, "sex", \%sex );
            my $perps = get_perps( $people, $p );
            if ( scalar(@$perps) > $MAX_PERPS ) {
                die "too many perps for case: " . dump($perps);
            }
            my $p_count = 1;
            for my $perp (@$perps) {
                for my $f (qw( id role sex )) {
                    $r->{"perp${p_count}_${f}"} = $perp->{$f};
                }
                remap( $r, "perp${p_count}_sex", \%sex );
                $p_count++;
            }
            push @rows, $r;
        }
    }
    return [@rows];
}

my @csv_header = qw(
    ref_id
    client_id
    intake_date
    age
    sex
    race
    afcars_id
    ref_type
    case_id
    case_opened_date
    case_closed_date
    service_accept_date
    call_screen_code
    service_decision_code
    allegation_code
);

for my $c ( ( 1 .. $MAX_PERPS ) ) {
    for my $f (qw( id role sex )) {
        push @csv_header, "perp${c}_$f";
    }
}

my $header   = [@csv_header];
my $csv_file = $a_file;
$csv_file =~ s,/[^/]+\.json,/data-set-2-norm.csv,;
print "Writing $csv_file\n";
my $csv = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
$csv->column_names($header);
open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
$csv->print( $fh, $header );

for my $ref_id ( keys %recs ) {
    my $rows = build_rows( $recs{$ref_id} );
    for my $r (@$rows) {
        $csv->print_hr( $fh, $r );
        $fh->flush;
    }
}

close $fh;
