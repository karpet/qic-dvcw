#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_mdy_cat read_json trim );

my %MAP = (
    "CYCIS Case ID"              => "CYCIS_case_id",   # TODO child_state_id ?
    "Person ID"                  => "person_id",
    "NCANDS encrypted Person ID" => "NCANDS_id",
    "SACWIS Case ID"             => "SACWIS_case_id",  # TODO child_state_id ?
    "ID_FAM_GRP"                 => "fam_group_id",    # TODO child_state_id
    "CRTKR1ID"                   => "CRTKR1ID",
    "CRTKR2ID"                   => "CRTKR2ID",
    "Provider"                   => "provider",
    "Team"                       => "team",
    "Worker"                     => "caseworker_name",
    "Month"                      => "month",
    "IP Visit Occurred"          => "in_person_visits",
    "Video Visit Occurred"       => "video_visits",
    "IP + Video Visit Occurred"  => "",
    "Visit Required"             => "",
    "Visit Occurred in Residence"    => "",
    "Video Counted as in Residence"  => "",
    "In Res + Video Visits Occurred" => "",
);

# warn just once per file
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

    return $normed;
}

my @csv_header = qw(
    CYCIS_case_id
    person_id
    NCANDS_id
    SACWIS_case_id
    fam_group_id
    CRTKR1ID
    CRTKR2ID
    provider
    team
    caseworker_name
    month
    in_person_visits
    video_visits
);

for my $json_file (@ARGV) {
    my $buf      = read_json($json_file);
    my $header   = [@csv_header];
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

