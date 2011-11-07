#!/usr/bin/env perl
# Just pop up an xterm and run the chrox program in it!
# If chrox.pl is still running (lockfile: chrox.lock) then this will still 
# pop up a new window.  That window will say that it's waiting for the 
# previous chrox window to close.
# But if you call this when there are already 2 popups (one running and one
# waiting) then this will not launch a 3rd one.

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

use Getopt::Long;
my($force);
GetOptions('force' => \$force);  # $force now says whether --force was included

#if ($#ARGV != 0) { die "Usage: $0 <user>\n"; }
#$usr = shift;
#$usr =~ s/\.log$//;  # in case called with usr.log instead of just usr

$| = 1;  # autoflush STDOUT.

if($force) { counter(-999); }

my $i = counter(0);
if($i > 1) { 
  print "There are already $i chrox popups open. Not launching. " . 
        "Use --force to override or delete ${path}.chrox\n";
  exit(1);
}

$ENV{DISPLAY} = ":0.0";  # have to set this explicitly if invoked by cron.

my($sec,$min,$hour) = localtime(time - $nytz);

counter(1);
# man xterm for all these fancy options...
system("/usr/X11R6/bin/xterm -T '${hour}occ CHROCK' " . 
       "-fg white -bg darkviolet -cr green -bc -rw -e ${path}chrox.pl");
counter(-1);



#SCHDEL (SCHEDULED FOR DELETION):
#sysopen(LF, "$path/chrox.lock", O_RDONLY | O_CREAT) or die "lock3: $!";
#if(!flock(LF, LOCK_EX | LOCK_NB)) {
  #dlog("failed to acquire lock 1 in launch.pl\n");
  ## chrox.lock is held. that means we should acquire chrox2.lock before 
  ## launching this second popup so that a 3rd attempt to launch a popup
  ## will fail.
  #sysopen(LFT, "$path/chrox2.lock", O_RDONLY | O_CREAT) or die "lock4: $!";
  #if(!flock(LFT, LOCK_EX | LOCK_NB)) {  # exclusive, nonblocking lock.
    #dlog("failed to acquire lock 2 in launch.pl\n");
    ## we couldn't get the 2nd lock, so there is already a popup waiting for
    ## another to finish. in that case exit this launcher without doing anything.
    #print "There is already one chrox popup waiting for another to finish. ".
          #"Exiting.\n";
    #exit(1);
  #} else {
    #dlog("acquired lock 2 in launch.pl\n");
  #}
#} else {
  #dlog("acquired lock 1 in launch.pl -- releasing it immediately\n");
  #close(LF);  # if we can get chrox.lock then release it and do nothing.
#}

#close(LFT);  # release the lock.
