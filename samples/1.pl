#!/usr/bin/perl

use strict;
use warnings;
use Murex::Base
use Data::Dumper::Simple;

# Initialize Logging -----------------------------------

use Log::Log4perl qw(get_logger);
Log::Log4perl->init_and_watch("log.conf", 60);
my $logger = get_logger();
$logger->info("Program started.");

# Initialize Configuration -----------------------------

my $configobject = Murex::Base->new(basedir=>"/hfx/home/develop/ml7tre/OOTest/conf/");
$configobject->readfile(type=>"csv",
                        filename=>"Murex_Environments.csv",
		       );
$configobject->readfile(type=>"csv",
                        filename=>"Reports.csv",
		       );
$configobject->readfile(type=>"csv",
                        filename=>"Eod_Schedule.csv",
		       );
$configobject->readfile(type=>"xml",
                        filename=>"MurexEnv_all.xml",
		       );
$configobject->readfile(type=>"xml",
                        filename=>"MurexEnv_ml7tre.xml",
		       );

$configobject->mergeconf("MergedXML","MurexEnv_all.xml","MurexEnv_ml7tre.xml");

# Processing -------------------------------------------

open DUMPER,">dumper.txt";
print DUMPER Dumper($configobject);
close DUMPER;

#$configobject->output(template=>"template.tt",environment=>"envname");
$configobject->output(template=>"envlist.tt",environment=>"envname");

$logger->info("Program ended.");

1;
