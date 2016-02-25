package Daemond::Stat::Graphite;


use strict;
use Socket         qw(PF_INET SOCK_DGRAM);
use AnyEvent::Util qw(fh_nonblocking);
use Mouse;

# use Data::Dumper;

has 'host',   is => 'ro', required => 1;
has 'port',   is => 'ro', required => 1;
has 'prefix', is => 'ro', required => 1;

has 'sock',   is => 'rw';
has 'paddr',  is => 'rw';

has 'retry',  is => 'rw';

sub BUILD {
	my $self = shift;
	$self->mksock();
}

sub mksock {
	my $self = shift;

	my $phost = gethostbyname($self->host) or die;
	my $paddr = Socket::sockaddr_in($self->port, $phost);

	socket(my $sock, PF_INET, SOCK_DGRAM, getprotobyname('udp'))
		or warn 'Failed to create graphite udp socket '.$self->host.':'.$self->port.": $!", return;

	$self->paddr($paddr);
	$self->sock($sock);

	fh_nonblocking $sock,1;
	connect($sock,$paddr) or warn "Failed to connect graphite udp socket:$!", return;

	1;
}

sub send : method {
	my $self = shift;

	warn 'no socket', return unless $self->sock;

	my ($param,$value,$timestamp) = @_;
	$timestamp ||= time();

	my $data = $self->prefix."$param $value $timestamp\n";

	warn ">> $data";

	defined(send($self->sock, $data, 0, $self->paddr))
		or warn("send ethine failed: $!"), return;

	1;
}


1;
