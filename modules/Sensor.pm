#!/usr/bin/perl

package Sensor;

use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
my %family_data = (
 '1D' => ['counters.A', 'counters.B'],
 '10' => ['temperature', 'power'],
 '12' => ['sensed.A', 'sensed.B', 'PIO.A', 'PIO.B', 'power'],
 '29' => ['sensed.0', 'sensed.1', 'sensed.2', 'sensed.3', 'sensed.4', 'sensed.5', 'sensed.6', 'sensed.7', 'PIO.0', 'PIO.1', 'PIO.2', 'PIO.3', 'PIO.4', 'PIO.5', 'PIO.6', 'PIO.7', 'power'],
 '30' => ['current', 'power'],
 'FF' => ['counters.A'],
);
	
	# Declare the subroutines
  sub read_fully($$);
  sub read_value($$$);

  sub read_fully($$) {
   my $owserver=shift;
   my $ow_id = shift;
   my $family = read_value($owserver,$ow_id,'family');

   my %values = ();
   foreach (@{$family_data{$family}}) {
    my $key = $_;
    $key =~ s/\./_/g;
    $values{$key}=read_value($owserver,$ow_id,$_);
   }
   return %values;
  }

  sub read_value($$$) {
   my $owserver = shift;
	 my $oneWireID = shift;
   my $value = shift;
   my $reading = $owserver->read("$oneWireID/$value");
   chomp $reading if defined $reading && "" ne $reading;
   if (defined $reading && $reading ne "") {
    $reading  =~ s/\s+//;
   }
   return $reading;
  }

1;
