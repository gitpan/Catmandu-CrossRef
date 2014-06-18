#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::CrossRef';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = $pkg->new(doi => "10.1577/H02-043", usr => "bla", pwd => "blub");

done_testing;
