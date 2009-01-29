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

die "Can't create temporary schema without a schema name" unless $schema;
die "Invalid schema name" unless $schema =~ /^[a-zA-Z0-9_-]+$/;

print STDERR "Reading schema file.\n";
open SCHEMA, "$this_dir/modencode_experiment_schema.sql" or die "Couldn't open chado_public_only.sql to create Chado schema";
# Load in a new schema
my $schema_ddl = "";
{
  local $/; # Slurp mode on
  $schema_ddl = <SCHEMA>;
}
close SCHEMA;
print STDERR "Done.\n";

$schema_ddl =~ s/\$temporary_chado_schema_name\$/$schema/g;

print STDERR "Generating temporary schema in Chado for $schema.\n";
my $dbh = DBI->connect($dsn, $user, $password, { PrintWarn => 0 }) or die "Couldn't connect to database identified by $dsn";
$dbh->do("DROP SCHEMA IF EXISTS $schema CASCADE") or die "Couldn't drop schema $schema, but it exists";
$dbh->do("DROP SCHEMA IF EXISTS ${schema}_data CASCADE") or die "Couldn't drop schema ${schema}_data, but it exists";
$dbh->do($schema_ddl) or die "Couldn't create empty chado schema named $schema";
$dbh->disconnect();
print STDERR "Done.\n";

print STDERR "Loading chadoxml.\n";
$ENV{'PERL5LIB'} = join(":", @INC);
system("$this_dir/stag-storenode.pl", @orig_args);
if ($? == 0) {
  print STDERR "Done.\n";
} else {
  print STDERR "Failed!\n";
  exit(-1);
}

exit 0;
