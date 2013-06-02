# Rough implementation of HipChat API calls for Tocks
# See https://www.hipchat.com/docs/api

# Get your HipChat auth token in your HipChat settings
# and set a global variable like $hipauth = "abc123";
# (That's already done in Tocks settings but if you're using this elsewhere
# you'll need to set $hipauth.)

use LWP::UserAgent;  # tip: run 'sudo cpan' and at the cpan prompt do 'upgrade'
#use JSON;            # then 'install LWP::UserAgent' and 'install JSON' etc
use HTTP::Request::Common;  # pjf recomends cpanmin.us
use URI::Escape;

$hipbase = "https://api.hipchat.com/v1/rooms/";

# Send a message m to HipChat
sub hipsend { my($m) = @_;
  my $ua = LWP::UserAgent->new;
  my $uri = $hipbase."message?auth_token=$hipauth".
                            "&notify=1".
                            "&color=purple".
                            "&room_id=$hiproom".
                            "&from=$hipfrom+tock".
                            "&message=".uri_escape($m);
  my $resp = $ua->get($uri);
  hiperr('GET', $uri, $resp);
}

# Takes request type (GET, POST, etc), uri string, and response object; 
# barfs verbosely if problems. Obviously this isn't the best way to do this.
sub hiperr { my($rt, $uri, $resp) = @_; 
  if(!$resp->is_success) {
    print "Error making the following $rt request to HipChat:\n$uri\n";
    print $resp->status_line, "\n", $resp->content, "\n";
    exit 1;
  }
}

1; # when requiring a library in perl it has to return 1.

