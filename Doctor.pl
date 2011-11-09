#!/usr/bin/perl -w

####################################################
# Based on the bus_order property of the sensors
# this utility checks the network for broken/missing
# sensors and cable breakages.
####################################################

use strict;
use warnings;
use DBI;
use DBD::SQLite;
use XML::Simple;

# OWDS Modules
use FindBin;                 # locate this script
use lib "$FindBin::Bin";
use modules::Sensor;
use modules::OwDB;
use modules::OwDS;
# Read Program Settings
my $conf = XMLin('configuration/settings.xml');

# Create owserver object
my $owserver = OwDS::get_owserver($conf);

# Connection to SQLite DB file
my $dbh = OwDB::get_handle();

# SENSORS
my $query = "select one_wire_id, location, bus_order from sensors order by bus_order asc";
my $query_handle = $dbh->prepare($query);
$query_handle->execute();

# Read and insert one measurement per sensor into the database.
$query_handle->bind_columns( \my ( $ow_id, $location, $bus_order) );
my $previous_location="your server";
my $result=1;
my $sensor_missing=0;
my @missing_sensors=();
my $previous_ok_location=0;
my $broken_cable=0;
my $broken_sensors=0;

while ( $query_handle->fetch() ) {
#  next if ($ow_id =~ m/81|FF\./g);
  $ow_id =~ s/\d{2}\.//g;
  $result = Sensor::ping( $owserver, $ow_id ); # or die "Problems at \"$location\", either the sensor is broken or the connection between ${previous_location} and $location is broken.";
  if ( $result ) {
   print "$previous_location ---> $location [OK]\n";
   $broken_sensors=$sensor_missing;
   $previous_ok_location=$location;
   $broken_cable=0;
  } else {
   unless ($sensor_missing) {
    print "$previous_location ---> $location [FAIL]\n";
    $sensor_missing=$location;
    $broken_cable= "$previous_ok_location and $location";
   }
   push (@missing_sensors , $location);
  }
  $previous_location=$location;
}

unless ($sensor_missing) {
 print "\nNetwork OK.\n";
} else {
 print "\n";
 if($broken_cable) {
  print "Network is broken, there is a cable breakage between $broken_cable.\n";
 }
  print "Network test failed. There are broken/missing sensors;\n";
  foreach my $sensor (@missing_sensors) {
   print "$sensor\n";
  }
}

# Close connection
$query_handle->finish;
undef($dbh);





