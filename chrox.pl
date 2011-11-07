#!/usr/bin/env perl
# Chrock Tracker -- prompt for and log chrocks.
# by Danny Reeves and Bethany Soule -- 2007 March 14

require "$ENV{HOME}/.chroxrc";
require "${path}util.pl";

## Possible paths to chrox.  Add yours.
#@chroxpath = (
#  "$ENV{HOME}/prj/chrox",
#  "$ENV{HOME}/factory/chrox",
#);
## Make $path the first of the above that actually exists.
#for(@chroxpath) { if(-e $_) { $path = $_;  last; } }
#die "Chrox path not found.\n" unless defined($path);

$SVN = "/usr/bin/svn";

#if($#ARGV != 0) { die "Usage: $0 <user>\n"; }
#$usr = shift;
#$usr =~ s/\.log$//;  # in case called with usr.log instead of just usr

use Fcntl qw(:DEFAULT :flock);  # (needed despite inclusion in util.pl)

$| = 1;  # autoflush STDOUT.

print STDERR "\a";  # beep!

sysopen(LF, "${path}$usr.log", O_RDONLY | O_CREAT) or die;
if(!flock(LF, LOCK_EX | LOCK_NB)) {  # exclusive, nonblocking lock.
  print "Waiting for the previous chrox window to close...";
  flock(LF, LOCK_EX) or die "Can't lock ${path}chrox.lock: $!";
  print " done!\n\n";
}

my($year,$mon,$mday,$hour) = dt();

#06-29 14:00:10 TUE dreeves ___ [[time]] :chrock :done :fail :edit :void :smack
my $tmptime = ts(time - $nytz);
$tmptime =~ s/^\d{4,4}\-//;
print "$tmptime $usr ___ [[time]] :chrock :done :fail :edit :void :smack\n";
print "Enter something you'll finish in the ".
  $hour."occ. (add :chrock to count for money)\n\n";
my $a = <STDIN>;
chomp($a);  # input the goal (should trim whitespace from front and back)
my $start = time - $nytz;
clog(ts($start)." $usr $a [[");

($year,$mon,$mday,$hour,$min,$sec) = dt($start);
my ($yt, $mt, $dt, $ht, $mt, $st) = dt($start+$CHR);
print "\n--> STARTED ${hour}occ ($hour:$min:$sec -> $ht:$mt:$st)... (hitting ENTER stops the clock)\n\n";
#clocksoff();
my $b = <STDIN>;
chomp($b);
my $end = time - $nytz;
print "\n--> STOPPED after " . ss($end-$start) . 
                              " (add tags like :void :done :fail :edit)\n\n";
#clockson();
clog(ss($end-$start)."]] $b");
my $c = <STDIN>;  chomp($c);
## turn words into tags:
#$c =~ s/(\s+|\s*\,\s*)/\ /g;
#my @tags = split(' ', $c);
#for (@tags) { s/^\:?/\:/; }  # add the optional colons
#clog(join(' ', @tags)."\n");
clog(" $c\n");

my $abc = $a . $b . $c;
if ($abc=~ /\:edit\b/) { system("/usr/bin/vi + ${path}$usr.log"); }

close(LF);  # release the lock.

print "\nChecking ${usr}'s log into git...\n";
system("cd $path; $GIT add ${path}$usr.log");
system("cd $path; $GIT commit ${path}$usr.log -m \"AUTO-CHECKIN $usr\"");
system("cd $path; $GIT pull; $GIT push");
system("${path}score.pl ${path}*.log | /usr/bin/less +G");


# SCRATCH AREA ################################################

#while ($k !~/chrock|frock|void/){
#  print "Specify category (chrock/frock/void): ";
#  $k = <STDIN>;  chomp($k);
#}
#if ($k ne "void"){
#  while ($d !~/done|fail|edit/){
#    print "Specify success (done/fail/edit): ";
#    $d = <STDIN>;  chomp($d);
#  }
#}
#clog(ss($end-$start)."]] $k $d\n");


#sleep(30);   # for debugging.
# while(time<$ansTm+45*60) {
#   print STDERR ".";
#   sleep(60);
# }
