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

# Declare the subroutines
sub update_sensor_property($$$);
sub get_sensor_property($$);


sub get_sensor_property($$) {
 my $sensor_id = shift;
 my $property = shift;
 my $sql = "SELECT $property FROM SENSORS WHERE one_wire_id = '$sensor_id'";
 return get_single_value($sql);
}

sub update_sensor_property($$$) {
  my $sensor_id = shift;
  my $property = shift;
  my $value =shift;
  my $dbh = DBI->connect($dsn, $user, $pwd);
  my $sql = "UPDATE SENSORS SET $property = ? where one_wire_id = ?";
  my $sth = $dbh->prepare_cached($sql);
  $sth->execute($value, $sensor_id) or return 0;
  undef $dbh;
  return 1;
}

sub get_rain_since($$) {
 my $rain_sensor = get_sensor_by_family("1D");
 print $rain_sensor;
}

sub get_counts_since($$$) {
 my $sensor_id = shift;
 my $counter = shift;
 my $since_date = shift;
 my $to_date;
 return get_counts_between($sensor_id, $counter, $since_date, $to_date);
}

sub get_counts_between($$$$) {
  
}

sub get_sensor_by_family($) {
 my $family = shift;
 my $sql = "select one_wire_id from sensors where one_wire_id like '$family%'";
 return get_single_value($sql);
}

sub get_single_value($) {
 my $sql = shift;
 my $dbh = DBI->connect($dsn, $user, $pwd);
 my $sth = $dbh->prepare($sql);
 $sth->execute();
 my $ret = "apa";
 while (my @data = $sth->fetchrow_array()) {
  $ret = $data[0];
 }
 undef $dbh;
 return $ret;
}


1;
