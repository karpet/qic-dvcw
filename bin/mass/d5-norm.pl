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
    "QIC Person ID"             => "child_state_id",
    "CONTACT_DATE"              => "contact_date",
    "CONTACT_METHOD_CODE_DESC"  => "contact_method",
    "CONTACT_PURPOSE_CODE_DESC" => "contact_purpose",
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
        $normed->{$f} = parse_date_mdy( $normed->{$f} );
    }

    for my $k ( keys %$normed ) {
        trim( $normed->{$k} );
    }

    return $normed;
}

my @csv_header = qw(
    child_state_id
    in_person_visits
    video_visits
    month
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

    my %monthlies;
    for my $rec (@$buf) {
        my $normed = norm_rec( $json_file, $rec );

        my $month = $normed->{contact_date};
        $month =~ s/\-\d\d$//;
        my $id = $normed->{child_state_id};
        my $k  = "$month:$id";
        $monthlies{$k}->{in_person_visits}++ if $normed->{contact_method} !~ /video/i;
        $monthlies{$k}->{video_visits}++ if $normed->{contact_method} =~ /video/i;
    }

    for my $k ( sort keys %monthlies ) {
        my ( $month, $id ) = split( ":", $k );
        my $r = {
            child_state_id => $id,
            month          => $month,
            %{ $monthlies{$k} },
        };
        $csv->print_hr( $fh, $r );
    }

    close $fh;
}
