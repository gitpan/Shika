use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Shika' }

diag("Shika is currently running in " .
    ($Shika::PurePerl ? "PurePerl" : "XS") . " mode on perl $]");
