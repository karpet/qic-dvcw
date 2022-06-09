#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_abbrev read_json trim );

my $usage     = "$0 d3-file.json d2-file.json";
my $ds_3_file = shift or die $usage;
my $ds_2_file = shift or die $usage;

my $d3_recs = read_json($ds_3_file);
my $d2_recs = csv( in => $ds_2_file, headers => 'auto' );

my %d3;
my %d2;

for my $d3r (@$d3_recs) {
    $d3{ $d3r->{CAS_ID} } = $d3r->{REGIONAL_OFFICE};
}

for my $d2r (@$d2_recs) {
    next unless $d2r->{case_id};
    $d2{ $d2r->{case_id} } = $d2r->{afcars_id};
}

print "case_id,afcars_id,regional_office\n";
for my $case_id ( keys %d3 ) {
    printf( "%s,%s,%s\n", $case_id, ($d2{$case_id} || ""), $d3{$case_id} );
}
