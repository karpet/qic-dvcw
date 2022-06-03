#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_abbrev read_json trim );

my %MAP = (
    "CONTACT_ID"      => "contact_id",
    "CAS_ID"          => "case_id",
    "REFER_ID"        => "referral_id",
    "CONTACT_DATE"    => "contact_date",
    "TYPE_LOCATION"   => "contact_method",
    "ORIGIN"          => "contacted_by",
    "CONTACT_BY"      => "contacted_by_detail",
    "Adult_CLIENT_ID" => "adult_id",
    "CHILD_CLIENT_ID" => "child_state_id",
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
    my %contacts;
    for my $rec (@$buf) {
        my $normed = norm_rec( $json_file, $rec );

        my $month = $normed->{contact_date};
        $month =~ s/\-\d\d$//;
        my $id         = $normed->{child_state_id};
        my $contact_id = $normed->{contact_id};

        # count child only once per contact id
        # (can appear once for each adult)
        next if $contacts{"$id:$contact_id"}++;

        my $k = "$month:$id";
        next if exists $monthlies{$k};
        next unless $normed->{contact_method} =~ /face to face|video conf/i;
        $monthlies{$k}->{in_person_visits}++
            if $normed->{contact_method} =~ /face to face/i;
        $monthlies{$k}->{video_visits}++
            if $normed->{contact_method} =~ /video conf/i;
    }

    for my $k ( sort keys %monthlies ) {
        my ( $month, $id ) = split( ":", $k );
        my $r = {
            child_state_id => $id,
            month          => $month,
            %{ $monthlies{$k} },
        };
        $csv->print_hr( $fh, $r );
        $fh->flush;
    }

    close $fh;
}
