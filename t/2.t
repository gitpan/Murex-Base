use Murex::Base;
use Test::More tests => 3;
# Initialize Logging -----------------------------------

use Log::Log4perl qw(get_logger);
Log::Log4perl->init_and_watch("log.conf", 60);
my $logger = get_logger();

# Initialize Configuration -----------------------------

BEGIN {
   use_ok( 'Murex::Base' );
}
require_ok( 'Murex::Base' );

my $configobject=Murex::Base->new(basedir=>"./");
my $filename="murexcfg.tmp";

open TEMPFILE,">$filename";
print TEMPFILE "This is a sample file. You can delete it!";
close TEMPFILE;

my $md5=$configobject->getmd5checksum(filename=>$filename);
cmp_ok($md5,"==","2a29080bea9e35f8f779a9d6477eb7b5","MD5");

unlink $filename;
