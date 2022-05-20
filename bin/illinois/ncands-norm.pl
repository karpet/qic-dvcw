#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_iso read_json trim );

my $ncands_fields = csv(
    in      => "$FindBin::Bin/../../eval/ncands-vars.csv",
    headers => "auto"
);
my @csv_header = map { $_->{name} } @$ncands_fields;
push @csv_header, "DOB";    # unofficial


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
        $normed->{ $MAP{$k} } = $rec->{$k};
    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    for my $f (@dates) {
        $normed->{$f} = parse_date_iso( $normed->{$f} );
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

