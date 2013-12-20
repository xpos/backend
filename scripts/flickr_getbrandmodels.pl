#!/usr/bin/perl

use strict;
use warnings;
use Flickr::API;
use Data::Dumper;
use vars qw( $flickr_api_key $flickr_api_secret $flickr_my_nsid $flickr_token
             $apiconf $api $response $content $colid $hold $id
	    );


$apiconf = (defined($ENV{FLICKR_API_RC})? $ENV{FLICKR_API_RC} :
            (defined($ENV{HOME})? "$ENV{HOME}/.flickrapirc" : "flickrapirc"));
do $apiconf || die "$0: can't load rc $apiconf: $!.\n";

$api = new Flickr::API({ 'key'    => $flickr_api_key,
                         'secret' => $flickr_api_secret });

print "Executing method : getting photosets\n";
$response = $api->execute_method('flickr.cameras.getBrandModels', {
     'api_key' => $flickr_api_key,
     'user_id' => '53876880@N02',
     'brand' => 'nikon'
});

print "Getting response\n";
print Dumper($response);

#$content = $$response{_content};

#print Dumper($content);
