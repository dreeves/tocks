#!/usr/bin/env perl
# Tock Tracker -- prompt for and log tocks (tock = 45-minute pomodoro).
# by Danny Reeves and Bethany Soule -- 2007 March 14

require "$ENV{HOME}/.tocksrc";
require "${path}util.pl";
require "${path}beemapi.pl";
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

#06-29 14:00:10 TUE dreeves ___ [[time]] :tock :done :edit :void :smac
my $tmptime = ts(time - $nytz*3600);
$tmptime =~ s/^\d{4,4}\-//;
print "$tmptime $usr ___ [[time]] :tock :void :smac :done :edit\n";
print "Enter task you'll finish in the ".
  $hour.":00 tock. (add :tock to count for money)\n\n";
my $a = <STDIN>;
chomp($a);  # input the goal (should trim whitespace from front and back)
$th = taskfetch();
$a =~ s/\:(\d+)\b/$th->{$1}/eg;
my $start = time - $nytz*3600;
tlog(ts($start)." $usr $a [[");

($year,$mon,$mday,$hour,$min,$sec) = dt($start);
my ($yt, $mt, $dt, $ht, $mt, $st) = dt($start+$TLEN);
print "\n--> STARTED ${hour}t ($hour:$min:$sec -> $ht:$mt:$st)... " .
      "(hitting ENTER stops the clock)\n\n";
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
if($abc =~ /\:edit\b/) {
  if($beemauth && $yoog) {
    print "\nRetype the tock task for Beeminder; ",
          "then also fix the tocks log.\n$abc\n";
    $abc = <STDIN>;
    chomp($abc);
    $abc =~ /\[([^\]]*)\]/;
    $elapsed = pss($1);
  }
  system("/usr/bin/vi + ${path}$usr.log");
}

# Rules for beeminding tocks:
# 1. Don't get pinged off task (that counts as -2 tocks!)
# 2. Try to pick things that take as long as possible without going over 45min
#    (it counts as a fractional tock if you finish early)
# 3. If you do go over 45min then it doesn't matter when you stop the clock or
#    whether you tag it done (it counts as 1/3 of a tock regardless)
# Nitty gritty:
# a. Must be a premeditated tock, ie, tag it :tock
# b. Tag it :done if you finish the task
# c. Stopping the clock after 45 minutes means it counts as 1/3 (done or not)
# d. Partial credit for finishing early: (stopping before 45m, tagging it :done)
#    If it takes x minutes to complete it counts for x/45, eg, 30 minutes = 2/3
# e. If you get pinged off task, enter :smac, which makes it count as -2!
# f. Tag it :void for a legit interruption and it won't count at all
if($beemauth && $yoog && $abc =~ /\:tock\b/ && $abc !~ /\:void\b/) {
  my $bval; # value to send to beeminder
  my $smacval = -2;  # what it counts as if you get smac'd, in [-10,0]
  my $overval = 1/3; # how much it counts if you go over, in [0,1]
  if($abc =~ /\:smac\b/) { $bval = $smacval; }
  elsif($abc =~ /\:done\b/ && $elapsed<=$tocklen) { $bval = $elapsed/$tocklen; }
  elsif($elapsed > $tocklen) { $bval = $overval; }
  my($year, $mon, $day) = dt();
  print "Sending to beeminder.com/$yoog\n$day $bval \"$abc\"\n";
  beebop($yoog, time, $bval, $abc);
}

close(LF);  # release the lock.

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
