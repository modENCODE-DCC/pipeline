#!/usr/bin/perl

use strict;

use Cwd qw();
use File::Basename qw();
use Getopt::Long;
use DBI;

my $this_dir = File::Basename::dirname(Cwd::realpath($0));
my ($dsn, $user, $password, $schema);

my @orig_args = @ARGV;

my %opts = (
  'd' => \$dsn,
  'user' => \$user,
  'password' => \$password,
  'schema' => \$schema,
);
Getopt::Long::Configure("pass_through");
GetOptions(
  \%opts,
  'd|db=s',
  'user=s',
  'password=s',
  'schema|s=s',
);

die "Can't drop temporary schema without a schema name" unless $schema;
die "Invalid schema name" unless $schema =~ /^[a-zA-Z0-9_-]+$/;

print STDERR "Removing temporary schema in Chado for $schema.\n";
my $dbh = DBI->connect($dsn, $user, $password, { PrintWarn => 0 }) or die "Couldn't connect to database identified by $dsn";
$dbh->do("DROP SCHEMA IF EXISTS $schema CASCADE") or die "Couldn't drop schema $schema, but it exists";
$dbh->disconnect();
print STDERR "Done.\n";

exit 0;
