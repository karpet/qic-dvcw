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
    parse_date
    parse_date_ymd
    parse_date_mdy
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

sub parse_date {
    my $date = shift or return undef;

    my @parts = split( /[\/\-]/, $date );
    if ( grep { length($_) == 4 } @parts ) {
        return $date;
    }
    if ( $parts[0] > 31 or $parts[0] == 0 ) {
        return parse_date_ymd($date);
    }
    return parse_date_mdy($date);
}

sub parse_date_ymd {
    my $date = shift or return undef;

    my ( $year2, $month, $day )
        = ( $date =~ m,^(\d+)/(\d+)/(\d+), );    # "72/3/29"
    my $year = $year2 > 22 ? "19$year2" : "20$year2";
    $day   = "0$day"   if length($day) == 1;
    $month = "0$month" if length($month) == 1;
    return "$year-$month-$day";
}

sub parse_date_mdy {
    my $date = shift or return undef;

    my ( $month, $day, $year2 ) = ( $date =~ m,^(\d+)/(\d+)/(\d+), );
    my $year = $year2 > 22 ? "19$year2" : "20$year2";
    $day   = "0$day"   if length($day) == 1;
    $month = "0$month" if length($month) == 1;
    return "$year-$month-$day";
}

sub clean_zip {
    my $z = shift;
    return $z unless defined $z;
    $z = clean_name($z);
    $z = "0$z" if length($z) < 5;
    if ( length($z) == 9 ) {
        my ( $p1, $p2 ) = ( $z =~ m/^(\d\d\d\d\d)(\d\d\d\d)$/ );
        $z = "$p1-$p2";
    }
    return $z;
}

sub clean_state {
    my $s = shift;
    return $s unless defined $s;
    $s = clean_name($s);
    return "MA" if $s eq "Massachusetts";
    return "IL" if $s eq "Illinois";
    return $s;
}

1;
