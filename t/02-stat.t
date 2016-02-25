 #!/usr/bin/env perl

use 5.010;
use strict;
use lib::abs '../lib';
use Test::More;
use Data::Dumper;
use YAML ();

BEGIN {
	use_ok( 'Daemond::Stat' );
}

my $config = YAML::Load(<<'...');
---
- end: 'udp://127.0.0.1:20020'
  prefix: 'pref1'
- end: 'udp://127.0.0.1:20021'
  prefix: 'pref2'
  name: 'alter_ego'
- end: 'tcp://127.0.0.1:20022'
  prefix: 'pref3'
  name: 'alter_ego_tcp'
...

# warn Dumper $config;

my $stat1 = Daemond::Stat->new( $config );

$stat1->('metric1','value1');
$stat1->send('metric2','value2');
$stat1->loc1('metric3','value3');
$stat1->alter_ego('metric4','value4');

my $result1;
*Daemond::Stat::Graphite::send = sub { $result1 = $_[1] };
$stat1->alter_ego('metric5.5','value5');
is $result1, 'metric5.5', 'call method same as existing endpoint';

my $result2;
*Daemond::Stat::Graphite::send = sub { $result2 = $_[1] };
$stat1->location('metric5.6','value6');
is $result2, undef,'call method for non-existing endpoint';

done_testing();
