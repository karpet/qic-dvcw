package QIC::Utils;
use strict;
use JSON;
use File::Slurper qw( read_text write_text read_binary );
use Exporter qw(import);

our @EXPORT = qw(
    write_json
    read_json
    clean_name
    clean_zip
    clean_state
    parse_date_ymd
);

sub write_json {
    my ( $filename, $struct ) = @_;
    write_text( $filename, to_json( $struct, { utf8 => 1, pretty => 1 } ) );
}

sub read_json {
    my ($filename) = @_;
    from_json( read_binary($filename) );
}

sub clean_name {
    my $n = shift;
    return undef if !defined($n);
    $n =~ s/^\s+|\s+$//g;
    return $n;
}

sub parse_date_ymd {
    my $date = shift or return undef;

    my ( $year2, $month, $day )
        = ( $date =~ m,^(\d+)/(\d+)/(\d+), );    # "72/3/29"
    my $year = $year2 > 20 ? "19$year2" : "20$year2";
    $day   = "0$day"   if length($day) == 1;
    $month = "0$month" if length($month) == 1;
    return "$year-$month-$day";
}

sub clean_zip {
    my $z = shift;
    return $z unless defined $z;
    $z = clean_name($z);
    $z = "0$z" if length($z) < 5;
    return $z;
}

sub clean_state {
    my $s = shift;
    return $s unless defined $s;
    $s = clean_name($s);
    return "MA" if $s eq "Massachusetts";
    return $s;
}

1;
