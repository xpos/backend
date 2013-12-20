#!/usr/bin/perl

use strict;
use warnings;
use Flickr::API;
use Data::Dumper;

my $flickr_api_key;
my $flickr_api_secret;
my $api;
my $apiconf;
my $response;
my $content;
my $frob;
my $sig;
my $url;

$apiconf = (defined($ENV{FLICKR_API_RC})? $ENV{FLICKR_API_RC} :
            (defined($ENV{HOME})? "$ENV{HOME}/.flickrapirc" : "flickrapirc"));
do $apiconf || die "$0: can't load rc $apiconf: $!.\n";

$api = new Flickr::API({ 'key'    => $flickr_api_key,
                         'secret' => $flickr_api_secret });



$response = $api->execute_method('flickr.auth.getFrob', {
# 'api_sig' => $sig,
});

$content = $$response{_content};

if ($content =~ m:<frob>([^<]+)</frob>:) { 
  $frob=$1;
} else {
  print "$0: did not find frob in response:\n$content\n";
  exit;
}
print "\$frob = $frob\n\n";

$url = $api->request_auth_url('delete', $frob);
print "\napi url:\n$url\n";

if(!open(CONF, ">> $apiconf")) {
  die "$0: Cannot open $apiconf to save frob: $!\n";
}
print CONF "\$flickr_frob = '$frob';\n";
close CONF;

print "\nVisit the URL, then run gettoken\n";

__END__
my $api = new Flickr::API({'key'    => 'your_api_key',
'secret' => 'your_app_secret'});

my $response = $api->execute_method('flickr.test.echo', {
'foo' => 'bar',
'baz' => 'quux',
});

