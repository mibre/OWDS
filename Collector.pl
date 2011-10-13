#!/usr/bin/perl -w

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
# Read Program Settings
my $conf = XMLin('configuration/settings.xml');

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

# Connection to SQLite DB file
my $dbfile = "./data/owds.db";
my $dsn = "dbi:SQLite:dbname=$dbfile";
my $user = "";
my $pwd = "";
my $dbh = DBI->connect($dsn, $user, $pwd);
# Print DB properties
print "Using SQLite version: $dbh->{sqlite_version}\n";

# SENSORS
my $query = "select one_wire_id from sensors";
my $query_handle = $dbh->prepare($query);
$query_handle->execute();

# Read and insert one measurement per sensor into the database.
$query_handle->bind_columns( \my ( $ow_id ) );
while ( $query_handle->fetch() ) {
  next if ($ow_id =~ m/81|FF\./g);
	my %sensor_values = Sensor::read_fully( $owserver, $ow_id );
	print "Adding values for sensor $ow_id\n";
  my $columns = "";
  my $values = "";
  my $nothing_new = 0;
  foreach my $column (keys %sensor_values) {
   if ( $column ne "" ) {
     my $separator = $columns ne "" ? ", " : "";
     $columns = $columns . $separator . $column; 
     $values = $values . $separator . $sensor_values{$column}; 
     if( $column =~ m/counters/) {
      my $sql = "select $column from sensor_data where sensor_id = '$ow_id' order by sensor_data_time asc";
      my $previous = OwDB::get_single_value($sql);
      print "Previous countervalue: $previous\n";
      my $current = $sensor_values{$column};
      $previous = $current-1 if $previous eq 'apa';
      my $new = $current-$previous;
      $new = $current if ($current < $previous);
#      $columns = $columns . $separator . "\"" . $column . "_new\"";
      $columns = $columns . "," . $column . "_new";
      $values = $values . "," . $new;
      $nothing_new = $new < 1;
     }
   }
  }
  my $sql = "insert into sensor_data (sensor_id, $columns, sensor_data_time) values (\"$ow_id\", $values, current_timestamp)";
  $dbh->do($sql) unless $nothing_new;	
}

# Close connection
$query_handle->finish;
undef($dbh);





