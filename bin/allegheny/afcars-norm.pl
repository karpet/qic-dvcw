#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw( dump );
use Text::CSV_XS qw( csv );
use File::Slurper qw( read_lines );
use FindBin;
use lib "$FindBin::Bin/../../lib";
use QIC::Utils qw( parse_date_iso read_json trim );

# AFCARS col heads
my @CSV_HEADER = read_lines("$FindBin::Bin/../../eval/afcars-vars.txt");

# dump \@CSV_HEADER;

my %MAP = (
    "Local Agency FIPS Code"                => "FIPSCode",
    "Record Number"                         => "RecNumbr",
    "Date of Birth"                         => "DOB",
    "Sex"                                   => "Sex",
    "Race: American Indian / Alaska Native" => "AmIAKN",
    "Race: Asian"                           => "Asian",
    "Race: Black / African American"        => "BlkAfrAm",
    "Race: Hawaiian / Pacific Islander"     => "HawaiiPI",
    "Race: White"                           => "White",
    "Race: Unable to Determine"             => "UnToDetm",
    "Hispanic or Latino Ethnicity"          => "HisOrgin",
    "Has the Child Been Clinically Diagnosed as having a Disability(ies)" =>
        "ClinDis",
    "Disability: Mental Retardation"              => "MR",
    "Disability: Visually or Hearing Impaired"    => "VisHear",
    "Disability: Physically Disabled"             => "PhyDis",
    "Disability: Emotionally Disturbed (DSM III)" => "EmotDist",
    "Disability: Other Medically Diagnosed Condition Requiring Special Care"
        => "OtherMed",
    "Date of First Removal"            => "Rem1Dt",
    "Date of Latest Removal from home" => "LatRemDt",
    "Total Number of Removals"         => "TotalRem",
    "Number of Previous Placement Settings During Each Removal Episode" =>
        "NumPlep",
    "Date Placement in Current Foster Care Setting (final placement of episode)"
        => "CurSetDt",
    "Manner of Removal"                          => "ManRem",
    "Removal Reason: Physical Abuse"             => "PhyAbuse",
    "Removal Reason: Sexual Abuse"               => "SexAbuse",
    "Removal Reason: Neglect"                    => "Neglect",
    "Removal Reason: Alcohol Abuse (Parent)"     => "AAParent",
    "Removal Reason: Drug Abuse (Parent)"        => "DAParent",
    "Removal Reason: Alcohol Abuse (Child)"      => "AAChild",
    "Removal Reason: Drug Abuse (Child)"         => "DAChild",
    "Removal Reason: Child’s Disability"         => "ChildDis",
    "Removal Reason: Child’s Behavior Problem"   => "ChBehPrb",
    "Removal Reason: Death of Parent(s)"         => "PrtsDied",
    "Removal Reason: Incarceration of Parent(s)" => "PrtsJail",
    "Removal Reason: Caretaker’s Inability to Cope Due to Illness or Other Reasons"
        => "NoCope",
    "Removal Reason: Abandonment"                         => "Abandmnt",
    "Removal Reason: Relinquishment"                      => "Relinqsh",
    "Removal Reason: Inadequate Housing"                  => "Housing",
    "Placement Setting Type (final placement of episode)" => "CurPlSet",
    "Most Recent Case Plan Goal"                          => "CaseGoal",
);

# warn just once per file
my %warned = ();

sub norm_rec {
    my ( $file, $rec ) = @_;

    my $normed = {};
    $normed->{State} = 42;
    $normed->{St}    = "PA";

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

    return $normed;
}

for my $json_file (@ARGV) {
    my $buf       = read_json($json_file);
    my $first_rec = $buf->[0];
    my %not_in_map
        = map { $_ => $_ } grep { $_ and !exists $MAP{$_} } keys %$first_rec;
    my $header   = [ @CSV_HEADER, keys %not_in_map ];
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

