#!/usr/bin/env perl
# Tock Tracker -- prompt for and log tocks (tock = 45-minute pomodoro).
# by Danny Reeves and Bethany Soule -- 2007 March 14

require "$ENV{HOME}/.tocksrc";
require "${path}util.pl";
require "${path}beemapi.pl";
require "${path}hipapi.pl";
use Data::Dumper; $Data::Dumper::Terse = 1;


use Fcntl qw(:DEFAULT :flock);  # (needed despite inclusion in util.pl)

my $tskf = "${ttpath}$usr.tsk"; # TagTime task file
my $th; # task hash, maps task numbers to task strings from tagtime task file

$| = 1;  # autoflush STDOUT.

print STDERR "\a";  # beep!

sysopen(LF, "${path}$usr.log", O_RDONLY | O_CREAT) or die;
if(!flock(LF, LOCK_EX | LOCK_NB)) {  # exclusive, nonblocking lock.
  print "Waiting for the previous tocks window to close...";
  flock(LF, LOCK_EX) or die "Lock problem: $!";
  print " done!\n\n";
}

my($year,$mon,$mday,$hour) = dt(time - $nytz*3600);

# print the active tasks in the tagtime task file, if present
if(-e $tskf) {  # show pending tasks
  if(open(F, "<$tskf")) {
    while(<F>) {
      if(/^\-{4,}/ || /^x\s/i) { print; last; }
      if(/^(\d+)\s+\S/) {
        print;
        #$tags{$1} = gettags($_);  # hash mapping task num to tags string
      } else { print; }
    }
    close(F);
  } else {
    print "ERROR: Can't read task file ($tskf)\n";
    #$eflag++;
  }
  print "\n";
}

#06-29 14:00:10 TUE dreeves ___ [[time]] :done :edit :void :smac
my $tmptime = ts(time - $nytz*3600);
$tmptime =~ s/^\d{4,4}\-//;
print "$tmptime $usr ___ [[time]] :void :smac :done :edit\n";
print "Enter task you'll finish in the ".
  $hour.":00 tock...\n\n";
my $a = <STDIN>;
chomp($a);  # input the goal (should trim whitespace from front and back)
$th = taskfetch();
my $orig = $a;
$a =~ s/\:(\d+)\b/$th->{$1}/eg;
if($a ne $orig) { print "$a\n"; }
my $start = time - $nytz*3600;
tlog(ts($start)." $usr $a [[");

($year,$mon,$mday,$hour,$min,$sec) = dt($start);
my ($yt, $mt, $dt, $ht, $mt, $st) = dt($start+$TLEN);
print "\n--> STARTED ${hour}t ($hour:$min:$sec -> $ht:$mt:$st)... " .
      "(hitting ENTER stops the clock)\n\n";
hipsend("${hour}oct: $a [$hour:$min -> $ht:$mt]");
#clocksoff();
my $b = <STDIN>;
chomp($b);
$th = taskfetch();
$b =~ s/\:(\d+)\b/$th->{$1}/eg;
my $end = time - $nytz*3600;
my $elapsed = $end-$start;
print "\n--> STOPPED after " . ss($elapsed) . 
                               " (add tags :void :smac :done :edit)\n\n";
#clockson();
tlog(ss($elapsed)."]] $b");
my $c = <STDIN>;
print "---------------------------------------------------------------------\n";
chomp($c);
$th = taskfetch();
$c =~ s/\:(\d+)\b/$th->{$1}/eg;
## turn words into tags:
#$c =~ s/(\s+|\s*\,\s*)/\ /g;
#my @tags = split(' ', $c);
#for (@tags) { s/^\:?/\:/; }  # add the optional colons
#tlog(join(' ', @tags)."\n");
tlog(" $c\n");

my $abc = "$a $b $c [".ss($elapsed)."]";
my $bc  =    "$b $c [".ss($elapsed)."]";
if($abc =~ /\:edit\b/) {
  if($beemauth && $yoog) {
    print "\nRetype the tock task for Beeminder; ",
          "then also fix the tocks log.\n$abc\n";
    $abc = <STDIN>;
    chomp($abc);
    $abc =~ /\[([^\]]*)\]/;
    $elapsed = pss($1);
  } else {
    system("/usr/bin/vi + ${path}$usr.log");
  }
}

hipsend("$bc <a href=\"https://www.beeminder.com/$yoog\">".
             "bmndr.com/$yoog</a>");
#            "<img src=\"https://www.beeminder.com/${yoog}-thumb.png\"/></a>");

# See README.md for the rules for beeminding tocks
if($beemauth && $yoog && $abc !~ /\:void\b/) {
  my $smacval = -2;    # what it counts as if you get smac'd, in [-10,0]
  my $overval = 1/2;   # how much it counts if you go over, in [0,1]
  my $bval = 0;        # actual value to send to beeminder
  if($abc =~ /\:(smack?|smk)\b/) { $bval = $smacval; }
  elsif($abc =~ /\:done\b/ && $elapsed<=$tocklen) { $bval = $elapsed/$tocklen; }
  elsif($elapsed > $tocklen) { $bval = $overval; }
  my($year, $mon, $day) = dt();
  if($bval != 0) { 
    print "Sending to beeminder.com/$yoog\n$day $bval \"$abc\"\n";
    beebop($yoog, time, $bval, $abc);
  } else {
    print "Not sending to Beeminder with value $bval.\n";
    print "(NB: If you end early without tagging it :done ", 
          "it doesn't count for anything.)\n";
  }
}

close(LF);  # release the lock.

print "[press enter to dismiss]"; my $tmp = <STDIN>;

#print "\nChecking ${usr}'s log into git...\n";
#system("cd $path; $GIT add ${path}$usr.log");
#system("cd $path; $GIT commit ${path}$usr.log -m \"AUTO-CHECKIN $usr\"");
#system("cd $path; $GIT pull; $GIT push");
#system("${path}score.pl ${path}*.log | /usr/bin/less +G");


# Return a hashref mapping tagtime task numbers to the full task strings
sub taskfetch { 
  my %h;
  if(-e $tskf) {
    if(open(F, "<$tskf")) {
      while(<F>) {
        if(/^\-{4,}/ || /^x\s/i) { last; }
        if(/^(\d+)\s+(.*)/) {
          $h{$1} = "$1 $2";
        }
      }
    }
    close(F);
  } else {
    print "ERROR: Can't read task file ($tskf)\n";
  }
  return \%h;
}
