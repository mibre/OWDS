#!/usr/bin/perl

package OwDB;

use strict;
use warnings;
use DBI;
use Exporter;
our @ISA = qw(Exporter);

# Connection to SQLite DB file
my $dbfile = "./data/owds.db";
my $dsn = "dbi:SQLite:dbname=$dbfile";
my $user = "";
my $pwd = "";

# Declare the subroutines
sub update_sensor_property($$$);
sub get_sensor_property($$);
sub get_rain_since($$);
sub get_single_value($);
sub get_handle();

sub get_handle() {
 return DBI->connect($dsn, $user, $pwd);
}

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
 my $since = shift;
 my $sensor_location = shift;
 my $tips_since = get_counts_since($sensor_location, "counters_B_new", $since);
 my $rain_since = 0;
 $rain_since = 0.253 * $tips_since if defined $tips_since;
 return $rain_since;
}

sub get_temperature($$$$) {
  my $location = shift;
  my $type= shift;
  my $since = shift;
  my $until = shift;
  my $ret = "";
  my $sql = "select temperature from sensor_data where location = '$location'";
  defined $location or die "You must at least give me a location to work with...\nTry something like 'Presenter.pl --show temperature --at [location]\nSee https://github.com/mibre/OWDS/wiki/\n";
  my $maxminavg = $type;
  if ($maxminavg =~ m/(max|min|avg)/i) {
   $sql = "select $1(temperature) from sensor_data where location = '$location'";
  }
  $sql = $sql . " and sensor_data_time > $since" if defined $since;
  $sql = $sql . " order by sensor_data_time desc limit 0,1";
  $ret = get_single_value($sql);
  return $ret;
}

sub get_counts_since($$$) {
 my $location = shift;
 my $counter = shift;
 my $since_date = shift;
 my $to_date = "datetime('now')";
 return get_counts_between($location, $counter, $since_date, $to_date);
}

sub get_counts_between($$$$) {
  my $location = shift;
  my $counter = shift;
  my $since = shift;
  my $to_date = shift;
  my $sql = "select sum($counter) from sensor_data where location='$location' and sensor_data_time >= $since and sensor_data_time <= $to_date;";
  return get_single_value($sql);
}

sub get_sensor_by_family($) {
 my $family = shift;
 my $sql = "select one_wire_id from sensors where one_wire_id like '$family%'";
 return get_single_value($sql);
}

sub get_sensor_by_name($) {
 my $name = shift;
 my $sql = "select one_wire_id from sensors where name = '$name'";
 return get_single_value($sql);
}

sub get_sensor_by_location($) {
 my $location = shift;
 my $sql = "select one_wire_id from sensors where location = '$location'";
 return get_single_value($sql);
}

sub get_single_value($) {
 my $sql = shift;
 my $dbh = DBI->connect($dsn, $user, $pwd);
 my $sth = $dbh->prepare($sql);
 $sth->execute();
 my $ret = "apa";
 if (my @columns = $sth->fetchrow_array()) {
  $ret = $columns[0];
 }
 undef $dbh;
 return $ret;
}


1;
