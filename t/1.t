# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Murex-Config.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { 
   use_ok('Murex::Base'); 
   use_ok('Data::Dumper::Simple');
   use_ok('Log::Dispatch');
   use_ok('Log::Dispatch::FileRotate');
   use_ok('Log::Log4perl');
   use_ok('Mail::Sendmail');
   use_ok('Log::Dispatch::Email');
   use_ok('XML::Simple');
   use_ok('Crypt::RC6');
   use_ok('Hash::Merge');
   use_ok('Digest::MD5');
   use_ok('English');
   use_ok('Template');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

