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
    "Encrypted PERS ID" => "federal_child_id",       # maybe AFCARS or NCANDS?
    "PersonId"          => "state_child_id",         #
    "SacwisCaseId"      => "case_id",                #
    "Case Start Date"   => "case_date",
    "County"            => "region_name",
    "Description"       => "DV_reason_or_allegation",
    "Where DV Found"    => "where_DV_found",
    "CDRESP"            => "risk_score",
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
    federal_child_id
    state_child_id
    case_id
    case_date
    region_name
    DV_reason_or_allegation
    where_DV_found
    risk_score
);

for my $dir (@ARGV) {
    my $adults_file = "$dir/Adult-Members.json";
    my $cases_file  = "$dir/Cases.json";
    my $adults_buf  = read_json($adults_file);
    my $cases_buf   = read_json($cases_file);
    my $header      = [@csv_header];
    my $csv_file    = "$dir/norm.csv";
    my $csv
        = Text::CSV_XS->new( { binary => 1, eol => $/, auto_diag => 1, } );
    $csv->column_names($header);
    open my $fh, ">:encoding(utf8)", $csv_file or die "$csv_file: $!";
    $csv->print( $fh, $header );

    # build adult lookup
    my %adults = ();
    for my $adult (@$adults_buf) {
        $adults{ $adult->{PersonId} } ||= [];
        push @{ $adults{ $adult->{PersonId} } }, $adult->{SacwisCaseId};
    }

    for my $rec (@$cases_buf) {
        if ( exists $adults{ $rec->{PersonId} }
            and grep { $_ eq $rec->{SacwisCaseId} }
            @{ $adults{ $rec->{PersonId} } } )
        {
        }
        else {
        }
        my $normed = norm_rec( $cases_file, $rec );

        $csv->print_hr( $fh, $normed );
    }

    close $fh;
}

