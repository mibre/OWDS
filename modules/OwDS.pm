#!/usr/bin/perl
package OwDS;

use strict;
use warnings;
use DBI;
use Exporter;
our @ISA = qw(Exporter);

sub get_owserver($);

sub get_owserver($) {
 my $conf = shift;
 # Create owserver object
 my $ownet_host = $conf->{owserver}->{host};
 my $ownet_port = $conf->{owserver}->{port};
 my $ownet_warnings = $conf->{owserver}->{warnings};
 my $ownet_scale = $conf->{owserver}->{scale};
 my $owserver = undef;
 if (lc $conf->{owfs_or_owserver} eq "owfs") {
  use modules::OwFs;
  $owserver = OwFs->new();
  $owserver->ow_dir($conf->{owfs}->{dir});
 } else {
  use OWNet;
  $owserver = OWNet->new('$ownet_host:$ownet_port $ownet_warnings $ownet_scale');
 }
 return $owserver;
}

1;
