#!/usr/bin/perl

use DBI;
use Getopt::Long;
# OWDS Modules
use FindBin;                 # locate this script
use lib "$FindBin::Bin";
use modules::Sensor;
use modules::OwDB;

# Connection to SQLite DB file
my $dbfile = "./data/owds.db";
my $dsn = "dbi:SQLite:dbname=$dbfile";
my $user = "";
my $pwd = "";
my $dbh = DBI->connect($dsn, $user, $pwd);

my ($measurement_type, $location, $since, $until);
$result = GetOptions ("show|measurement_type|mt=s" => \$measurement_type,
"at|location|l=s" => \$location,
"from|since|s=s" => \$since, # string
"to|until|t=s" => \$until,
);

if ($measurement_type eq  "rain") {
  print get_rain($since, $location) . "mm\n";
} elsif ($measurement_type =~ m/temp/) {
  print get_temperature($location, $type, $since, $until) . "\n";
} 

sub get_temperature($$$$) {
  my $location = shift;
  my $type= shift;
  my $since = shift;
  my $until = shift;
  my $ret = OwDB::get_temperature($location, $type, $since, $until);
  return $ret;
}

sub get_rain($$) {
 my $since = shift;
 my $location = shift;
 my $ret = OwDB::get_rain_since($since, $location);
 return $ret;
}

