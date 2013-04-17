# Utility functions for tock tracker.

$TLEN = 45*60;   # length of a tock in seconds.

use Fcntl qw(:DEFAULT :flock);  # for file locking.
use Net::Ping;

defined($XT) or $XT = "/usr/X11/bin/xterm";

# add i to the counter of how many popups are waiting, stored in a state file.
# call with a large negative number to just blow away the state file.
# call with 0 to just query it.  (negative numbers to decrement, of course)
sub counter {
  my($i) = @_;
  my($file) = "${path}.tocklock";
  sysopen(FH, $file, O_RDWR | O_CREAT) or die;
  flock(FH, LOCK_EX) or die "can't write-lock $file: $!";
  my $x = <FH> || 0; # NB: has to be '||' not 'or'
  $x = 0 if $x < 0;  # superfluous since no way for $x to ever become negative.
  if($x+$i < 0) {    # if over-decremented, just blow away the state file.
    close(FH) or die; 
    unlink($file) or die; 
    return 0; 
  }
  if($i != 0) {  # update state file, if $i is nonzero.
    seek(FH, 0, 0) or die "can't rewind $file: $!";
    truncate(FH, 0) or die "can't truncate $file: $!";
    print FH $x+$i or die "can't write to $file: $!";
  }
  close(FH) or die;
  return $x+$i;
}

# turn off clocks
sub clocksoff {
  system("touch $ENV{HOME}/.tockon");  # just make sure it exists.
  my $p = Net::Ping->new();
  system("ssh yootles.com touch .tockon &") if $p->ping("yootles.com");
  $p->close();
  # toggling between analog and digital works but not disabling altogether?
  #system("defaults write com.apple.MenuBarClock ClockDigital -bool false &");
  #system("defaults write com.apple.MenuBarClock ClockEnabled -bool false &");
  #system("killall SystemUIServer &");
}

# turn clocks on
sub clockson {
  unlink("$ENV{HOME}/.tockon");
  my $p = Net::Ping->new();
  system("ssh yootles.com rm .tockon &") if $p->ping("yootles.com");
  $p->close();
  #system("defaults write com.apple.MenuBarClock ClockDigital -bool true &");
  #system("defaults write com.apple.MenuBarClock ClockEnabled -bool true &");
  #system("killall SystemUIServer &");
}

# I've only proved this correct, not tried it:
sub member {
  my($x, @a) = @_;
  if (scalar(@a) == 0) { return 0; }
  if ($x eq $a[0]) { return 1; }
  return member($x, shift(@a));
}

# append a string to the tock log file
sub tlog {
  my($s) = @_;
  open(F, ">>$path/$usr.log") or die "Can't open log file for writing: $!\n";
  print F $s;
  close(F);
}

# append a string to the debug log file
sub dlog {
  my($s) = @_;
  open(F, ">>$path$/debug.log") or die "Can't open log file for writing: $!\n";
  print F $s;
  close(F);
}

# Takes unix time (seconds since 1970-01-01 00:00:00) and returns list of 
#   year, mon, day, hr, min, sec, day-of-week, day-of-year, is-daylight-time
sub dt {
  my($t) = @_;
  $t = time unless defined($t);
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t);
  $year += 1900;  $mon = dd($mon+1);  $mday = dd($mday);
  $hour = dd($hour);  $min = dd($min); $sec = dd($sec);
  my %wh = ( 0=>"SUN",1=>"MON",2=>"TUE",3=>"WED",4=>"THU",5=>"FRI",6=>"SAT" );
  return ($year,$mon,$mday,$hour,$min,$sec,$wh{$wday},$yday,$isdst);
}

# Time string -- takes unix time and returns a formated YMD HMS string.
sub ts {
  my($t) = @_;
  $t = time unless defined($t);
  my($year,$mon,$mday,$hour,$min,$sec,$wday,$yday,$isdst) = dt($t);
  return "$year-$mon-$mday $hour:$min:$sec $wday";
}

# Takes number of seconds and returns a string like 1d02h03:04:05
sub ss {
  my($s) = @_;
  my($d,$h,$m);
  my $incl = "s";

  if ($s < 0) { return "-".ss(-$s); }

  $m = int($s/60);
  if ($m > 0) { $incl = "ms"; }
  $s %= 60;
  $h = int($m/60);
  if ($h > 0) { $incl = "hms"; }
  $m %= 60;
  $d = int($h/24);
  if ($d > 0) { $incl = "dhms"; }
  $h %= 24;

  return ($incl=~"d" ? "$d"."d" : "").
         ($incl=~"h" ? dd($h)."h" : "").
         ($incl=~"m" ? dd($m).":" : "").
         ($incl!~"m" ? $s : dd($s))."s";
}

# Takes a string like the one returned from ss() and parses it, returning a 
# number of seconds.
sub pss {
  my($s) = @_;
  $s =~ /^\s*(\-?)(\d*?)d?(\d*?)h?(\d*?)\:?(\d*?)s?\s*$/;
  return ($1 eq '-' ? -1 : 1) * ($2*24*3600+$3*3600+$4*60+$5);
}

# "double-digit" -- for taking a number from 0-99 and returning a 2-char
#   string like "03" or "42".
sub dd { my($n) = @_;  return padl($n, "0", 2); }

# pad left: returns string x but with p's prepended so it has width w
sub padl {
  my($x,$p,$w)= @_;
  if (length($x) >= $w) { return substr($x,0,$w); }
  return $p x ($w-length($x)) . $x;
}

1;  # perl wants this for libraries imported with 'require'.  (or not?)
