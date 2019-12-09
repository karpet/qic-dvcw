package QIC::Case;
use strict;
use base qw( QIC::Record );

__PACKAGE__->meta->setup(
    table => 'cases',

    columns => [
        id             => { type => 'varchar', length => 16 },
        case_worker_id => { type => 'varchar', length => 16 },
        survey_name    => { type => 'varchar', length => 16 },
        surveyed_at    => { type => 'datetime' },
        created_at     => { type => 'datetime' },
        updated_at     => { type => 'datetime' },

    ],

    primary_key_columns => ['id'],

    foreign_keys => [
        case_worker => {
            class       => 'QIC::CaseWorker',
            key_columns => { case_worker_id => 'id' }
        }
    ],

    relationships => [
        adults => {
            class      => 'QIC::Adult',
            column_map => { id => 'case_id' },
            type       => 'one to many',
        },
        children => {
            class      => 'QIC::Child',
            column_map => { id => 'case_id' },
            type       => 'one to many',
        },
    ],
);

1;
