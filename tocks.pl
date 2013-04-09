#!/usr/bin/env perl
# Tock Tracker -- prompt for and log tocks (tock = 45-minute pomodoro).
# by Danny Reeves and Bethany Soule -- 2007 March 14

require "$ENV{HOME}/.tocksrc";
require "${path}util.pl";

use Fcntl qw(:DEFAULT :flock);  # (needed despite inclusion in util.pl)

$| = 1;  # autoflush STDOUT.

print STDERR "\a";  # beep!

sysopen(LF, "${path}$usr.log", O_RDONLY | O_CREAT) or die;
if(!flock(LF, LOCK_EX | LOCK_NB)) {  # exclusive, nonblocking lock.
  print "Waiting for the previous tocks window to close...";
  flock(LF, LOCK_EX) or die "Lock problem: $!";
  print " done!\n\n";
}

my($year,$mon,$mday,$hour) = dt(time - $nytz*3600);

#06-29 14:00:10 TUE dreeves ___ [[time]] :tock :done :fail :edit :void :smac
my $tmptime = ts(time - $nytz*3600);
$tmptime =~ s/^\d{4,4}\-//;
print "$tmptime $usr ___ [[time]] :tock :done :fail :edit :void :smac\n";
print "Enter task you'll finish in the ".
  $hour.":00 tock. (add :tock to count for money)\n\n";
my $a = <STDIN>;
chomp($a);  # input the goal (should trim whitespace from front and back)
my $start = time - $nytz*3600;
clog(ts($start)." $usr $a [[");

($year,$mon,$mday,$hour,$min,$sec) = dt($start);
my ($yt, $mt, $dt, $ht, $mt, $st) = dt($start+$TLEN);
print "\n--> STARTED ${hour}occ ($hour:$min:$sec -> $ht:$mt:$st)... (hitting ENTER stops the clock)\n\n";
#clocksoff();
my $b = <STDIN>;
chomp($b);
my $end = time - $nytz*3600;
print "\n--> STOPPED after " . ss($end-$start) . 
                               " (add tags :void :done :fail :edit :smac)\n\n";
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

