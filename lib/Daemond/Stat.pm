package Daemond::Stat;

use Mouse;
use Daemond::Stat::Graphite;

use overload
	'&{}'    => \&_to_code,
	fallback => 1,
;

my %IDX_DEST;

sub new {
	my $pkg  = shift;
	my $self = bless {}, $pkg;
	$self->_init(@_);
	return $self;
}

sub _init {
	my $self = shift;
	my $graphite_endpoints = shift;
	for (@$graphite_endpoints) {
		$_->{end} =~ m{^ (?<family>[^ ]+) :// (?<host>[^ ]+) : (?<port>[^ ]+) $}msx;
		if ( $+{family} eq 'udp' ) {
			my $connector = Daemond::Stat::Graphite->new(
				host   => $+{host},    port => $+{port},
				prefix => $$_{prefix}, name => $$_{name},
			);
			$IDX_DEST{$_->{name}} = $connector if exists $_->{name};
			if (ref $IDX_DEST{'all'} eq 'ARRAY') {
				push @{$IDX_DEST{'all'}}, $connector
			} else {
				$IDX_DEST{'all'} = [ $connector ];
			}
		}
	}
}

our $AUTOLOAD;
sub _to_code {
	my $self = shift;
	return sub {
		$AUTOLOAD = '';
		&AUTOLOAD($self,@_);
	}
}

sub AUTOLOAD {
	my $self = shift;
	if ($AUTOLOAD) {
		# choose concrete instance to send to
		my $name = (split '::', $AUTOLOAD)[-1];
		unless (exists $IDX_DEST{$name}) {
			warn "called send to endpoint $name but not found";
			return
		}
		$IDX_DEST{$name}->send(@_);
	} else {
		$_->send(@_) for @{$IDX_DEST{'all'}};
	}
}


1;
