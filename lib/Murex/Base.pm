=head1 NAME

Murex::Base 

=head1 ABSTRACT

Module to handle Murex MxG2000 Configurations

=head1 SYNOPSIS

use Murex::Base

=head1 DESCRIPTION

Module to handle Murex MxG2000 Configurations

=head2 EXPORT

None by default.

=cut


package Murex::Base;
$VERSION=0.08;

use strict;
use warnings;
use Data::Dumper::Simple;
use Log::Log4perl qw(get_logger);
use XML::Simple;
use Hash::Merge qw( merge );
use Crypt::RC6;
use Digest::MD5;
use English;
use Template;

=head2 LOGGING

This module expects a log.conf file to exist. This file contains the Log4Perl Configuration.

=cut

my $logger = get_logger();

=head2 Murex::Base->new(basedir=>"./")

Creates a new config object. Expects "basedir" to be set to the base directory.

Example:

   my $configobject = Murex::Base->new(basedir=>"/home/wherever/");

=cut

sub new {
   my ($class,%arg) = @_;
   $logger->debug(Dumper($class,%arg));

   my $objref = {
                   _basedir    => $arg{basedir},
                };
   bless $objref, $class;
   return $objref;
}

=head2 readfile(type=>"csv",filename=>"f.csv")

Reads an configuration file and applies it to the object.

Example:

   $configobject->readfile(type=>"csv",
                           filename=>"Eod_Schedule.csv",
	   	          );
   $configobject->readfile(type=>"xml",
                           filename=>"MurexEnv_all.xml",
		          );

=cut

sub readfile {
   my ($self, %params)=@_;
   my $inputfile = $self->{_basedir}.$params{filename};
   
   $logger->debug(Dumper(%params));
   $logger->logdie("File $inputfile does not exist.") unless (-e $inputfile);
   $logger->debug("Reading file $inputfile of type $params{type}");

   if ($params{type} eq "csv") {
      my @data=$self->_readfile_csv(filename=>$inputfile,seperator=>",",header=>"yes");
      $logger->debug("Applying file to object configuration");
      @{$self->{$params{filename}}}=@data;
   } elsif ($params{type} eq "xml") {
      my $data=$self->_readfile_xml(filename=>$inputfile);
      $logger->debug("Applying file to object configuration");
      $self->{$params{filename}}=$data;
   } else {
      $logger->logdie("I cannot handle that type of file at the moment");
   }
}

=head2 environmentinfo(name=>$e);

Retrieves information about an environment.

Example:

   my @envs=$configobject->environmentinfo(name=>$e);
   foreach my $result (@envs) {
      print Dumper($result);
   }

=cut

sub environmentinfo {
   my ($self, %params)=@_;
   $logger->debug(Dumper(%params));

   $logger->logdie("Data not read.") unless (defined($self->{"Murex_Environments.csv"}));

   my @results;
   foreach my $env (@{$self->{"Murex_Environments.csv"}}) {
      if ($env->{Name} eq $params{name}) {push @results, $env;};
   }
   return @results;
}

=head2 mergeconf("Merged","first.xml","second.xml")

Merges two configuration hash's into one. The last one is allowed to overwrite data from the first.

Example:

   $configobject->mergeconf("MergedXML","MurexEnv_all.xml","MurexEnv_ml7tre.xml");

=cut

sub mergeconf {
   my $self=shift;
   my $destination=shift;
   my @configs=@_;
   my $first=shift(@configs);
   my $second=shift(@configs);
   
   my %one=%{$self->{$first}};
   my %two=%{$self->{$second}};
   my %merged=%{merge(\%one,\%two)};
   %{$self->{$destination}}=%merged;
}

=head2 encrypt(seed=>"seed",password=>"password")

needs two strings as parameters (e.g. seed and password) and returns an
encrypted/decrypted value.

Example:

   $logger->info("Encrypted: ".$configobject->encrypt(seed=>"seed",password=>"password"));

=cut

sub encrypt
{
   my ($self, %params)=@_;
   $logger->debug(Dumper(%params));
    my $suppliedseed = $params{seed};
    my $pwd          = $params{password};
    my $seed     = sprintf("%-8.8s", $suppliedseed);
    my $password = sprintf("%-16s",  $pwd);
    my $key      = "";
    map { $key .= sprintf("%02lx", ord($_)); } split("", $seed);
    my $cipher             = new Crypt::RC6 $key;
    my $ciphertext         = $cipher->encrypt($password);
    my $encrypted_password = "";
    map { $encrypted_password .= sprintf("%02lx", ord($_)) }
    split("", $ciphertext);
    return $encrypted_password;
}

=head2 decrypt(seed=>"seed",password=>"7a29a1a99e53bb2d6c9f77893b017ed6"));

needs two strings as parameters (e.g. seed and password) and returns an
encrypted/decrypted value.

Example:

   $logger->info("Decrypted: ".$configobject->decrypt(seed=>"seed",password=>"7a29a1a99e53bb2d6c9f77893b017ed6"));

=cut

sub decrypt
{
    my ($self, %params)=@_;
    $logger->debug(Dumper(%params));
    my $seed  = $params{seed};
    my $crypt = $params{password};
    $seed = sprintf("%-8.8s", $seed);
    my $key = "";
    map { $key .= sprintf("%02lx", ord($_)); } split("", $seed);
    my $cipher = new Crypt::RC6 $key;
    my $ep     = "";

    while ($crypt =~ m/../g) { $ep .= chr(hex($MATCH)); }
    my $pwd = $cipher->decrypt($ep);
    $pwd =~ s/\s//g;
    return $pwd;
}

=head2 getmd5checksum(filename=>"log.conf"));

Returns a MD5 checksum for a given filename.

=cut

sub getmd5checksum{
   my ($self, %params)=@_;
   $logger->debug(Dumper(%params));
   my $filename=$params{filename};
   my $md5 = Digest::MD5->new;
   open(my $fh, "< $filename") or die "cant open file $filename";
   $md5->reset;
   $md5->addfile($fh);
   close $fh;
   return $md5->hexdigest;
}

=head2 output(template=>"template.tt",environment=>"envname");

Outputs to template toolkit

=cut

sub output {
   my ($self, %params)=@_;
   $logger->debug(Dumper(%params));
   my @results;
   foreach my $e (@{$self->{"Murex_Environments.csv"}}) {
      push @results, $e->{Name};
   }
   $logger->debug(join (",",@results));
   
   my $config = {
             INCLUDE_PATH => './templates/',  # or list ref
             INTERPOLATE  => 1,               # expand "$var" in plain text
             POST_CHOMP   => 0,               # cleanup whitespace
             PRE_PROCESS  => '',	      # prefix each template
             EVAL_PERL    => 1,               # evaluate Perl code blocks
   };

   # create Template object
   my $template = Template->new($config);

   # define template variables for replacement
   my $vars = {
       config  => $self,
   };

   # specify input filename, or file handle, text reference, etc.
   my $input = $params{template};

   # process input template, substituting variables
   $template->process($input, $vars)
       || die $template->error();

   
   return @results;
}


# ---

sub _readfile_csv {
   my ($self,%params)=@_;
   $logger->debug(Dumper(%params));
   
   $logger->logdie("Headerrow is missing.") if ($params{header} eq "no");

   open INFILE, "<".$params{filename};
   my $firstline=<INFILE>;
   chomp $firstline;
   my @header=split($params{seperator},$firstline);   
   my @content;
   while (<INFILE>) {
      chomp;
      my $entry;
      
      my @value=split($params{seperator},$_);
      my $i=0;
      foreach my $h (@header) {
         $entry->{$h} = $value[$i];
         $i++;
      }

      push @content, $entry;
   }
   close INFILE;
   return @content;
}

sub _readfile_xml {
   my ($self,%params)=@_;
   $logger->debug(Dumper(%params));

   my $ref = XMLin($params{filename});
   return $ref;
}

1;

=head1 SEE ALSO

   Visit the Murex User Group at http://www.linke.de/consulting/murex/usergroup

=head1 AUTHOR

   Markus Linke, E<lt>markus.linke@linke.deE<gt>.

=head1 COPYRIGHT AND LICENSE

   Copyright 2005 by Markus Linke. All rights reserved.
   NO commercial use without authors written permission!

=head1 AMENDMENT HISTORY

Please see Changes file.

=cut
