use strict;
use Test::More;
use Digest::MD5 'md5_hex';
use Time::HiRes 'usleep';

plan skip_all => 'Cannot run without linux?' if $^O ne 'linux';
plan skip_all => 'Cannot run without script/single' unless -x 'script/single';

my $command = 'sleep 1';
my $id = md5_hex $command;
my %info;

if (fork) {
  usleep 200e3;
  $ENV{ALREADY_RUNNING_STATUS} = 42;
  $ENV{SINGLE_SILENT} = !$ENV{HARNESS_IS_VERBOSE};
  ok -r "/tmp/single-$id", 'info file created';
  system 'script/single', $command;
  is $? >> 8, 42, 'already running';
  local @ARGV = ("/tmp/single-$id");
  chomp and /(\w+):\s*(.*)/ and $info{$1} = $2 while(<>);
  like $info{pid}, qr{^\d+$}, 'got pid';
  is $info{command}, $command, 'got command';
  is $info{id}, $id, 'got id';
  like $info{started}, qr/\b\d{4}\b/, 'got started';
  diag "Waiting for $command ...";
  wait;
  is $?, 0, 'command exit';
}
else {
  exec 'script/single', $command;
  die $!;
}

done_testing;