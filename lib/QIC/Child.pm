package QIC::Child;
use strict;
use base qw( QIC::Person );

__PACKAGE__->meta->setup(
    table => 'children',

    columns => [
        id           => { type => 'varchar', length => 32 },
        client_id    => { type => 'varchar', length => 32 },
        case_id      => { type => 'varchar', length => 16 },
        first_name   => { type => 'varchar', length => 255 },
        last_name    => { type => 'varchar', length => 255 },
        ethnicity    => { type => 'varchar', length => 255 },
        race         => { type => 'varchar', length => 255 },
        sex          => { type => 'varchar', length => 32 },
        gender       => { type => 'varchar', length => 32 },
        dob          => { type => 'date' },
        created_at   => { type => 'datetime' },
        updated_at   => { type => 'datetime' },

    ],

    primary_key_columns => ['id'],

    foreign_keys => [
        case => {
            class       => 'QIC::Case',
            key_columns => { case_id => 'id' }
        }
    ],
);

1;
