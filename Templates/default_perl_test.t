#!perl -T
#Template test structure
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;

my $module = $1 || '';
use_ok($module) || BAIL_OUT "Failed to use $module : [$!]";
dies_ok( sub { $module->new() }, 'New without settings fails correctly' );
my $obj = new_ok($module);

done_testing();
