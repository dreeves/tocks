# Rough implementation of Beeminder API calls needed for Tocks
# See http://beeminder.com/api

# Get your personal Beeminder auth token (after signing in) from
#   https://www.beeminder.com/api/v1/auth_token.json
# And set a global variable like $beemauth = "abc123";
# (That's already done in Tocks settings but if you're using this elsewhere
# you'll need to set $beemauth.)

use LWP::UserAgent;  # tip: run 'sudo cpan' and at the cpan prompt do 'upgrade'
#use JSON;            # then 'install LWP::UserAgent' and 'install JSON' etc
use HTTP::Request::Common;  # pjf recomends cpanmin.us
use Data::Dumper; $Data::Dumper::Terse = 1;
$beembase = 'https://www.beeminder.com/api/v1/';

# Create a new datapoint {timestamp t, value v, comment c} for bmndr.com/u/g
# and return the id of the new datapoint.
sub beebop { my($yoog, $t, $v, $c) = @_;
  my($u,$g) = split('/', $yoog);
  my $ua = LWP::UserAgent->new;
  my $uri = $beembase."users/$u/goals/$g/datapoints.json?auth_token=$beemauth";
  my $data = { timestamp => $t,
               value     => $v,
               comment   => $c };
  my $resp = $ua->post($uri, Content => $data);
  beemerr('POST', $uri, $data, $resp);
  #my $x = decode_json($resp->content);
  #return $x->{"id"};
}

# Takes request type (GET, POST, etc), uri string, hashref of data arguments, 
# and response object; barfs verbosely if problems. 
# Obviously this isn't the best way to do this.
sub beemerr { my($rt, $uri, $data, $resp) = @_; 
  if(!$resp->is_success) {
    print "Error making the following $rt request to Beeminder:\n$uri\n";
    print Dumper $data;
    print $resp->status_line, "\n", $resp->content, "\n";
    exit 1;
  }
}

1; # when requiring a library in perl it has to return 1.


# How Paul Fenwick does it in Perl:
#my ($user, $auth_token, $datapoint, $comment);  
#my $mech = WWW::Mechanize( autocheck => 1 )
#$mech->post(
#"http://beeminder.com/api/v1/users/$busr/goals/$slug/datapoints.json?
#auth_token=$auth_token",
#{
#  timestamp => time(),
#  value => $datapoint,
#  comment => $comment
#}
#);
