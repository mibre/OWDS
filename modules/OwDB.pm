#!/usr/bin/perl

package OwDB;

use strict;
use warnings;
use DBI;
use Exporter;
our @ISA = qw(Exporter);

# Connection to SQLite DB file
my $dbfile = "./owds.db";
my $dsn = "dbi:SQLite:dbname=$dbfile";
my $user = "";
my $pwd = "";
my $dbh = DBI->connect($dsn, $user, $pwd);

# Declare the subroutines
sub update_sensor_property($$$);
sub get_sensor_property($$);


sub get_sensor_property($$) {
 my $sensor_id = shift;
 my $property = shift;
 my $sql = "SELECT $property FROM SENSORS WHERE one_wire_id = \"$sensor_id\"";
 my $sth = $dbh->prepare($sql);
 my $ret = "";
 while (my @data = $sth->fetchrow_array()) {
  $ret = $data[1];
 }
 return $ret;
}

sub update_sensor_property($$$) {
  my $sensor_id = shift;
  my $property = shift;
  my $value =shift;
  my $sql = "UPDATE SENSORS SET $property = ? where one_wire_id = ?";
  my $update_handle = $dbh->prepare_cached($sql);
  $update_handle->execute($value, $sensor_id) or return 0;
  return 1;
}


1;
