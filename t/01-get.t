#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Importer::CrossRef';
  use_ok($pkg);
}
require_ok($pkg);

my %attrs = (
	doi=> '10.1577/H02-043',
	usr=> 'blurb',
	pwd => 'blurb'
);

my $importer = Catmandu::Importer::CrossRef->new(%attrs);

isa_ok($importer, $pkg);

can_ok($importer, 'each');

done_testing;