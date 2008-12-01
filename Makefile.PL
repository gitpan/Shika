use inc::Module::Install;
name 'Shika';
all_from 'lib/Shika.pm';

if ($]< 5.009_005) {
    requires 'MRO::Compat';
}

tests 't/*.t t/*/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
