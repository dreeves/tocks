#!/usr/bin/env perl
# Just pop up an xterm and run the tocks program in it!
# If tocks.pl is still running then this will still pop up a new window.
# That window will say that it's waiting for the previous tocks window to close.
# But if you call this when there are already 2 popups (one running and one
# waiting) then this will not launch a 3rd one.

require "$ENV{HOME}/.tocksrc";
require "${path}util.pl";

use Getopt::Long;
my($force);
GetOptions('force' => \$force);  # $force now says whether --force was included

$| = 1;  # autoflush STDOUT.

if($force) { counter(-999); }

my $i = counter(0);
if($i > 1) { 
  print "There are already $i tocks popups open. Not launching.\n" . 
        "Use --force to override, or delete ${path}.tocklock\n";
  exit(1);
}

$ENV{DISPLAY} = ":0.0";  # have to set this explicitly if invoked by cron.

my($sec,$min,$hour) = localtime(time - $nytz*3600);

counter(+1);
# man xterm for all these fancy options...
system("$XT -T \"${hour}t: the ${hour}'o'clock tock\" " . 
       "-fg white -bg darkviolet -cr green -bc -rw -e ${path}tocks.pl");
counter(-1);

