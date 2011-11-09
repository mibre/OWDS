#!/usr/bin/perl

package OwFs;

use strict;
use warnings;
use Data::Dumper;
use Exporter;
our @ISA = qw(Exporter);

sub read($);
sub ow_dir($);
sub dir($);

sub new {
 my $self  = {};
 $self->{OW_DIR}   = undef;
 bless($self);
 return $self;
}

sub dir($) {
 my $self = shift;
 my $dir = shift;
 my $ret = "";
 $dir = $self->{OW_DIR} . $dir;
 foreach my $file (<$dir/*>) {
  $ret = $ret . "," . $file;
 }
 return $ret;
}

sub ow_dir($) {
 my $self = shift;
 if (@_) { $self->{OW_DIR} = shift }
 return $self->{OW_DIR};
}

sub read($) {
  my $self = shift;
  my $sensor_id_and_value = shift;
  my $string = "";
  open FILE, "$self->{OW_DIR}/$sensor_id_and_value" or die "Couldn't open file: $sensor_id_and_value, $!";
  $string = <FILE>;
  close FILE;
  return $string;
}

1;
