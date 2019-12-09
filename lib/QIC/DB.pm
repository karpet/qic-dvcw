package QIC::DB;

use strict;
use base qw( Rose::DB );

use Carp;
use FindBin;
use Path::Class::File;

my $base_path;

for my $path ( "$FindBin::Bin/..", "$FindBin::Bin" ) {
    if ( -s Path::Class::File->new( $path, "qic.sql" ) ) {
        $base_path = $path;
    }
}

if ( !$base_path ) {
    croak "can't locate base path containing qic.sql using FindBin $FindBin::Bin";
}

my $sql = Path::Class::File->new( $base_path, 'qic.sql' );
my $db  = Path::Class::File->new( $base_path, 'qic.db' );

# create the db if it does not yet exist
if ( !-s $db ) {
    system("sqlite3 $db < $sql") and die "can't create $db with $sql: $!";
}

if ( !$db or !-s $db ) {
    croak "can't locate $db";
}

__PACKAGE__->register_db(
    domain          => 'default',
    type            => 'default',
    driver          => 'sqlite',
    database        => $db,
    auto_create     => 0,
    connect_options => {
        AutoCommit => 1,
        ( ( rand() < 0.5 ) ? ( FetchHashKeyName => 'NAME_lc' ) : () ),
    },
    post_connect_sql =>
        [ 'PRAGMA synchronous = OFF', 'PRAGMA temp_store = MEMORY', ],
);

1;
