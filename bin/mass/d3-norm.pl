#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_iso parse_date_mdy read_json trim );

my %MAP = (
    "REGION_NAME"                   => "region_name",
    "Region Name"                   => "region_name",
    "AREA_NAME"                     => "area_name",
    "QIC Worker ID"                 => "worker_id",
    "QIC Case ID"                   => "case_id",
    "QIC Person ID "                => "child_state_id",
    "FACTOR_DV_INT_APPR_DT (Child)" => "child_date",
    "FACTOR_DV_INV_APPR_DT (Case)"  => "case_date",
    "FACTOR_DV_FAAP_APPR_DT"        => "FAAP_date",
    "DV Presence"                   => "DV_presence",
    "RISK_ASM_SCORED_RISK_LEVEL"    => "ASM_scored_risk",
    "RISK_ASM_FINAL_RISK_LEVEL"     => "ASM_final_risk",
    "CONSULTATION_DATE"             => "consultation_date",
);

sub remap {
    my ( $rec, $field, $map ) = @_;
    if (! exists $rec->{$field}) {
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
    child_date
    case_date
    consultation_date
    FAAP_date
);

my %risks = (
    ""                                                     => "",
    "1. low"                                               => 1,
    "2. moderate"                                          => 2,
    "3. high"                                              => 3,
    "4. very high"                                         => 4,
    "clinical formulation supports the scored risk level." => "99",
    "no risk level"                                        => 0,
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
        $normed->{$f} = parse_date_mdy( $normed->{$f} );
    }

    for my $f (qw( ASM_scored_risk ASM_final_risk )) {
        $normed->{$f} ||= "";
        remap( $normed, $f, \%risks );
    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    return $normed;
}

my %uniq       = ();
my @csv_header = sort grep { !$uniq{$_}++ } values %MAP;

for my $json_file (@ARGV) {
    my $buf       = read_json($json_file);
    my $first_rec = $buf->[0];
    my %not_in_map
        = map { $_ => $_ } grep { $_ and !exists $MAP{$_} } keys %$first_rec;
    my $header   = [ @csv_header, keys %not_in_map ];
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
