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

#06-29 14:00:10 TUE dreeves ___ [[time]] :tock :done :fail :edit :void :smac
my $tmptime = ts(time - $nytz*3600);
$tmptime =~ s/^\d{4,4}\-//;
print "$tmptime $usr ___ [[time]] :tock :void :smac :fail :done :edit\n";
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
print "\n--> STOPPED after " . ss($end-$start) . 
                               " (add tags :void :smac :fail :done :edit)\n\n";
#clockson();
tlog(ss($end-$start)."]] $b");
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

my $abc = "$a $b $c [".ss($end-$start)."]";
if($abc =~ /\:edit\b/) {
  if($beemauth && $yoog && ) {
    print "\nRetype the tock task for Beeminder; ",
          "then also fix the tocks log.\n$abc\n";
    $abc = <STDIN>;
    chomp($abc);
  }
  system("/usr/bin/vi + ${path}$usr.log");
}

my $frac = ($end-$start)/(45*60);
if($frac>1) { $frac = 1; }

# send it to beeminder if it counts (it can count as at most 1 tock)
if($beemauth && $yoog &&  
   $abc =~ /\:tock\b/ &&  # has to be a premeditated tock 
   $abc !~ /\:void\b/ &&  # can't be voided (void = legit interruption)
   $abc !~ /\:smac\b/ &&  # no smacs (smac = getting tagtime-pinged off task)
   $abc !~ /\:fail\b/ &&
   ($frac < 1  && $abc =~ /\:done\b/ ||  # partial credit for early finish
    $frac == 1)                          # full credit for 45m of focused work 
  ) {
  print "Sending a +$frac to beeminder.com/$yoog\n";
  beebop($yoog, time, $frac, $abc);
}

close(LF);  # release the lock.

print "\nChecking ${usr}'s log into git...\n";
system("cd $path; $GIT add ${path}$usr.log");
system("cd $path; $GIT commit ${path}$usr.log -m \"AUTO-CHECKIN $usr\"");
system("cd $path; $GIT pull; $GIT push");
system("${path}score.pl ${path}*.log | /usr/bin/less +G");


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
