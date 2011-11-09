#!/usr/bin/perl
use File::Basename;
use XML::Simple;
use DBI;
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
my $xml_config = XMLin('configuration/settings.xml');
my $sensor_count = 0, $new_sensor_count=0;

print "####################################\n";
print "#      OWDS Setup                  #\n";
print "####################################\n"; 
print "\n";

print "Read from;\n  1, OWFS [Default]\n  2, OwServer\n [OPTIONAL]>  ";
my $read_choice = <STDIN>;
chomp $read_choice;
print "OK, you want to use $read_choice.\n";
if ($read_choice eq "2") {
  use OWNet;
  $read_choice = "owserver";
  print "Enter the address of your owserver [default: localhost]: ";
  $xml_config->{owserver}->{host} = <STDIN>;
  chomp $xml_config->{owserver}->{host};
  $xml_config->{owserver}->{address} = "localhost" if $xml_config->{owserver}->{address} eq "";
  print "Enter the port of your owserver [Default: 4304]: ";
  $xml_config->{owserver}->{port} =<STDIN>;
  chomp $xml_config->{owserver}->{port};
  $xml_config->{owserver}->{port} = "4304" if $xml_config->{owserver}->{port} eq "";
  print "Do you wish to log temperatures in Fahrenheit or Celsius? [f/C]: ";
  $xml_config->{owserver}->{warnings} = '-v';
  $xml_config->{owserver}->{scale} = "-" . uc <STDIN>;
  chomp $xml_config->{owserver}->{scale};
  $xml_config->{owserver}->{scale} = "-C" if $xml_config->{owserver}->{scale} eq "";
  $owserver = OWNet->new('$xml_config->{owserver}->{host}:$xml_config->{owserver}->{port} $xml_config->{owserver}->{warnings} $xml_config->{owserver}->{scale}'); 
  my $dirstring = $owserver->dir('/') ;
  if ( defined($dirstring) ) {  
     my @dir = split /,/ ,  $owserver->dir('/') ;
     foreach (@dir) {
      my $sensor_id = $_;
      my $add_ret = 0;
      if($sensor_id =~ m/[0-9A-Z]{2}\.[0-9A-Z]{12}/) {
       $add_ret = add_sensor($owserver, $sensor_id);
      }
     }
  }
} else {
  $read_choice = "OWFS";
  print "Please enter your 1wire mount point (something like /mnt/1wire/\n[REQUIRED] > ";
  my $mountpoint = <STDIN>;
  chomp $mountpoint;
  use modules::OwFs;
  $owserver = OwFs->new();
  $owserver->ow_dir($mountpoint);

  if (defined $mountpoint && !("" eq $mountpoint) && -d $mountpoint ) {
   print "Aah, so your 1wire network is mounted at $mountpoint!\nI will now see what devices I can find there...\n";
   foreach $file (<$mountpoint/*>){
     if ($file =~ m/[0-9A-Z]{2}\.[0-9A-Z]{12}/) {
      $sensor_count+=1;
      my $sensor_id = basename($file);
      $new_sensor_count+= add_sensor($owserver, $sensor_id);
     }
   } 
  } else {
   if ( !(-d $mountpoint) && $mountpoint ne "") {
    print "[$mountpoint] doesn't appear to be a directory...";
   } else {
    print "Sorry, but you need to enter a mountpoint.\n";
   }
   print "\nConfiguration failed.\n\n";
   exit 0;
  }
}
$xml_config->{owfs_or_owserver} = $read_choice;
print "Sensors found; $sensor_count, $new_sensor_count new.\n";
print "\nSensors configured.\n\n";
XMLout($xml_config, OutputFile => 'settings.xml',noattr => 1);


print "\nOWDS configured.\n";


sub sensor_exists {
 my $sensor_id = shift;
 my $sql = "SELECT * FROM SENSORS WHERE one_wire_id = \"$sensor_id\"";
 my @res = $dbh->selectrow_array($sql);
# print "Found @res occurrences of $sensor_id in DB...";
 return @res;
}

sub add_sensor {
  my $owconnection = shift;
  my $sensor_id = shift;  
  my $sensor_value = "";
  if($sensor_id =~ m/10\./g){
   $sensor_value = Sensor::read_value($owconnection,$sensor_id,"temperature");
  } elsif ($sensor_id =~ m/81|FF\./g) {
   return 0;
  }
  if (!sensor_exists($sensor_id)) {
    print "Adding sensor: " . $sensor_id . "[$sensor_value]\n";
    my $sql = "INSERT INTO SENSORS (name,date_added,one_wire_id) values ('$sensor_location', current_timestamp,'$sensor_id')";
    $dbh->do($sql);
#    sensor_property($sensor_id,"name");
    sensor_property($sensor_id,"location");
    sensor_property($sensor_id,"bus_order");
    return 1;
  } else {
    my $location = OwDB::get_sensor_property($sensor_id, "location");
    print "Said hi to old friend $sensor_id at $location[$sensor_value]\n";
#    sensor_property($sensor_id,"name");
    sensor_property($sensor_id,"location");
    sensor_property($sensor_id,"bus_order");
    return 0;
  }
}

sub sensor_property($$) {
 my $sensor_id = shift;
 my $p = shift;
 my $current = OwDB::get_sensor_property($sensor_id, $p);
 my $p_name = $p;
 $p_name =~ s/_/ /g;
 print "Current $p; $current\n";
 print "Do you wish to update its $p? [y/N]: ";
 my $upd_c = lc <STDIN>;
 chomp $upd_c;
 if ($upd_c eq "y") {
  print "Enter new $p: ";
  my $new_v = <STDIN>;
  chomp $new_v;
  my $res = OwDB::update_sensor_property($sensor_id, $p, $new_v) if $new_v ne "";
  print "Sensor $sensor_id\'s $p successfully updated from $current to $new_v.\n" if $res;
 }
}
