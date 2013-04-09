#!/usr/bin/env perl
# Reads log files specified on command line and computes balances.

# Possible paths to tocks.  Add yours.
@tockspath = (
  "$ENV{HOME}/prj/tocks",
  "$ENV{HOME}/factory/tocks",
);
# Make $path the first of the above that actually exists.
for(@tockspath) { if(-e $_) { $path = $_;  last; } }
die "Tocks path not found.\n" unless defined($path);

require "$path/util.pl";

$T = "tock";    # tag denoting that this tock counts for money.
$D = "done";    # tag denoting successful completion of a tock.
$F = "fail";    # tag denoting failure.
$V = "void";    # tag denoting that this tock should be voided.
$S = "smac";    # tag denoting an off-task ping on this tock.
$ANTE = 2;      # how much each puts in if >1 of them attempts a tock.
$SFEE = 20;     # smac fee: penalty for getting pinged off-task.

$unparsables = "";  # report of unparsable lines in log file.
$duplicates = "";   # report of duplicate entries in log file.
$badness = 0;       # whether there were any problems computing balances.
while(<>) {
  if(/^(\d\d\d\d)\-(\d\d)\-(\d\d)\ (\d\d)\:(\d\d)\:(\d\d)\ (\w\w\w)\ (\w+)\ (.*)\ ?\[\[(.*)\]\]\ (.*)$/) {
    $year = $1; $mon = $2; $day = $3; $hr = $4; $min = $5; $sec = $6;
    $wday = $7; $usr = $8; $x = $9; $t = pss($10); $y = $11;
    $xy = "$x $y"; # concatntn of user-entered stuff, before/after clock stopped
    $cat = ($xy =~ /\:$T/ ? $T : "");  # category: tock or not
    $suc = ($xy =~ /\:$D/ && $xy !~ /\:$F/ && $xy !~ /\:$S/ ? $D : "");
    $smk = ($cat eq $T && $xy =~ /\:$S/);
    $voi = ($xy =~ /\:$V/ ? $V : ""); # whether this entry contains :void tag.
    # (instead of both $voi and $cat we could just say that a :void tag cancels
    #  a :tock tag so both :tock and :void is equivalent to no :tock tag)

    # record a bunch of stuff about this tock...
    $uh{$usr}++;   # user hash
    $nh{$usr} += ($cat ne $T ? 1 : 0);  # num non-tocks
    $ah{$usr} += ($cat eq $T ? 1 : 0);  # num attempted tocks
    $yh{$usr} += ($cat eq $T && $suc eq $D ? 1:0); # num successful tocks
    $sc{$usr} += ($smk ? 1:0); # number of smacs (off-task pings)
    $tt{$usr} += $t;   # total time
    $tc{"$year.$mon.$day.$hr"}++;  # tock hash
    $hc{"$year.$mon.$day.$hr.$usr"}++; # tocks per hour per user should be <=1
    $ll{"$year.$mon.$day.$hr.$usr"} .= $_; # actual log line(s) for hour+user
    $th{"$year.$mon.$day.$hr.$usr"} = $t;  # time hash: seconds spent on tock
    $kh{"$year.$mon.$day.$hr.$usr"} = $cat;  # category hash: "tock" or ""
    $sh{"$year.$mon.$day.$hr.$usr"} = $suc;  # success hash: "done" or ""
    $sm{"$year.$mon.$day.$hr.$usr"} = $smk;  # smac hash: "smac" or ""
    $vh{"$year.$mon.$day.$hr.$usr"} = $voi;  # void hash: "void" or ""
  } else { 
    $unparsables .= $_; 
    $badness++;
  }
}

my @users = keys(%uh);
my @tocks = keys(%tc);
my %ytl;  # hash from user to yootles (money) balance.
for(@users) { $ytl{$_} = 0; } $ytl{"pot"} = 0;
for my $c (sort(@tocks)) {
  my($year,$mon,$day,$hr) = split('\.', $c); 
  my @partic = grep($kh{"$c.$_"} eq $T && $vh{"$c.$_"} ne $V, @users);
  my $wnr = $V;  # the winner!
  if(scalar(@partic) > 1) { 
    for my $u (@users) {
      #print "USER: $u\n";
      if($kh{"$c.$u"} eq $T) { $ytl{$u} -= $ANTE;  $ytl{"pot"} += $ANTE; }
    }
    for my $u (@users) {
      if($sm{"$c.$u"}) { $ytl{$u} -= $SFEE; $ytl{"pot"} += $SFEE; }
    }
    my @suc = sort { $th{"$c.$b"} <=> $th{"$c.$a"} }  # the succeeders.
      grep($kh{"$c.$_"} eq $T && $th{"$c.$_"} <= $TLEN &&
           $sh{"$c.$_"} eq $D, @users);
    if(scalar(@suc)>0) { $wnr = $suc[0]; } else { $wnr = "pot"; }
    my $booty = $ytl{"pot"};
    if($wnr ne $V) { $ytl{$wnr} += $booty;  $ytl{"pot"} -= $booty; }
  }
  print "$year-$mon-$day $hr: ",uc($wnr), summary($c,$wnr), " ";
  for(@users) {
    #print "[DEBUG: ", $th{"$c.$_"}, "]";
    if($_ ne $wnr && $th{"$c.$_"} ne "") { print "$_", summary($c,$_), " "; }
  }
  print "\n";
}
print "\n";

if($unparsables ne "") { print "BAD LOG LINES:\n$unparsables\n"; }
for(keys(%hc)) {
  if($hc{$_} > 1) { 
    $duplicates .= $ll{$_}; 
    $badness++;
  }
}
if($duplicates ne "") { 
  print "ONLY ONE ENTRY IS ALLOWED BETWEEN " . 
    "N'O'CLOCK AND N+1'O'CLOCK. PLEASE FIX THESE:\n$duplicates\n"; 
}

if($badness>0) {
  print "Number of problems with the log files (see above): $badness\n";
  print "  (They need to be fixed before balances can be computed.)\n";
  exit(1);
}

# Show various statistics...
print "Log entries:       ", join(', ', map("$_: $uh{$_}", @users)), "\n";
print "Non-tocks:         ", join(', ', map("$_: $nh{$_}", @users)), "\n";
print "Attempted tocks:   ", join(', ', map("$_: $ah{$_}", @users)), "\n";
print "Completed tocks:   ", join(', ', map("$_: $yh{$_}", @users)), "\n";
print "Smacks:            ", join(', ', map("$_: $sc{$_}", @users)), "\n";
print "Total time logged: ", join(', ', map("$_: ".ss($tt{$_}), @users)), "\n";
push(@users, "pot");
print "Net money: ", join(', ', map("$_: $ytl{$_}", @users)), "\n";


# summarize user's tock given tock string and user
sub summary { my($c,$u) = @_;
  if($u eq $V || $u eq "pot") { return ""; }
  my $t = $th{"$c.$u"};  # number of seconds spent
  my $k = $kh{"$c.$u"};  # category string (tock or nontock).
  if($k eq "") { $k = "non".$T; }
  my $s = $sh{"$c.$u"}; # success string: "done" or "" (meaning fail/smack/void)
  if($s eq "") { 
    if($sm{"$c.$u"}) {    $s = uc($S); } 
    elsif($vh{"$c.$u"}) { $s = $V;     }
    else {                $s = $F;     }
  }
  return "(", ss($t), " $k $s)";
}
