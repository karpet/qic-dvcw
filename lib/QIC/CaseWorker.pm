package QIC::CaseWorker;
use strict;
use base qw( QIC::Record );

__PACKAGE__->meta->setup(
    table => 'case_workers',

    columns => [
        id               => { type => 'varchar', length => 16 },
        first_name       => { type => 'varchar', length => 255 },
        last_name        => { type => 'varchar', length => 255 },
        email            => { type => 'varchar', length => 255 },
        site_name        => { type => 'varchar', length => 255 },
        site_office_name => { type => 'varchar', length => 255 },
        created_at       => { type => 'datetime' },
        updated_at       => { type => 'datetime' },

    ],

    primary_key_columns => ['id'],

    relationships => [
        cases => {
            class      => 'QIC::Case',
            column_map => { id => 'case_worker_id' },
            type       => 'one to many',
        },
    ],
);

1;
