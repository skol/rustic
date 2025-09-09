use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Enum::Rustic',
    VERSION_FROM  => 'lib/Enum/Rustic.pm',
    AUTHOR        => 'Igor Kaukin <i_kaukin@mail.ru>',
    LICENSE       => 'perl',
    ABSTRACT      => 'Rust-style enums (algebraic data types) for Perl',
    PREREQ_PM     => {
        'Carp' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/skol/Enum-Rustic.git',
                web  => 'https://github.com/skol/Enum-Rustic',
            },
            bugtracker => {
                web => 'https://github.com/skol/Enum-Rustic/issues',
            },
        },
    },
);