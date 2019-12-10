package QIC::Adult;
use strict;
use base qw( QIC::Record );

__PACKAGE__->meta->setup(
    table => 'adults',

    columns => [
        id           => { type => 'varchar', length => 32 },
        client_id    => { type => 'varchar', length => 16 },
        case_id      => { type => 'varchar', length => 16 },
        first_name   => { type => 'varchar', length => 255 },
        last_name    => { type => 'varchar', length => 255 },
        email        => { type => 'varchar', length => 255 },
        address_one  => { type => 'varchar', length => 255 },
        address_two  => { type => 'varchar', length => 255 },
        city         => { type => 'varchar', length => 255 },
        state        => { type => 'varchar', length => 255 },
        zipcode      => { type => 'varchar', length => 255 },
        sex          => { type => 'varchar', length => 32 },
        role         => { type => 'varchar', length => 32 },
        home_phone   => { type => 'varchar', length => 32 },
        work_phone   => { type => 'varchar', length => 32 },
        mobile_phone => { type => 'varchar', length => 32 },
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
