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

my $seed="seed";
my $password="password";
my $encrypted="7a29a1a99e53bb2d6c9f77893b017ed6";

my $encrypt=$configobject->encrypt(seed=>$seed,password=>$password);
my $decrypt=$configobject->decrypt(seed=>$seed,password=>$encrypted);
cmp_ok($password,"==",$decrypt,"Encryption/Decryption");
