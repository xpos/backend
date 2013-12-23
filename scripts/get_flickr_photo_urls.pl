#!/home/y/bin/perl

use strict;
use DBI;
use Data::Dumper;
use XML::Simple;
use LWP::UserAgent;


my $get_flickr_photo_id_qry = "select flickr_id from photo_has_exif";

my $dbh;
my @photo_ids = ();
my $image_ref = {};
my $flickr_photo_url_part1 = 'http://api.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=441348ae613407c5a3cc89a4b4bf758d&photo_id=';
my $flickr_photo_url_part2 = '&format=rest';

my $lwp = LWP::UserAgent->new;

sub connect_db {

	my $db;
	eval {
		$db = DBI->connect('dbi:mysql:xpos','','') or die "Connection Error: $DBI::errstr\n";
	};
	if ($@) {
		die "Unable to connect to DB : $@\n";
	}
	return $db;
}

sub get_flickr_photo_id {

	my ($db, $qry) = @_;

	my $sth = $db->prepare($qry);
	$sth->execute();
	while (my ($flickr_id) = $sth->fetchrow_array) {
		push @photo_ids, $flickr_id;
	}
	
	return @photo_ids;
}

#
# Get Photo Info
#
sub get_photo_info {

	my ($photo_id) = @_;
	my $content = "";
	
	my $url = "http://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=441348ae613407c5a3cc89a4b4bf758d&photo_id=".$photo_id."&format=rest";
	my $response = $lwp->get($url);
	print "-- Title, tag api: $url\n";
	my ($title, $tag);
        my @tags = ();
	
	if ($response->is_success) {	

	    $content = $response->decoded_content;
	    my $xml_ref = XMLin($content);
	    $title = $xml_ref->{'photo'}->{'title'};	
	    
	    if (exists $xml_ref->{'photo'}->{'tags'}->{'tag'}->{'raw'}) {
		push (@tags, $xml_ref->{'photo'}->{'tags'}->{'tag'}->{'raw'});
	    } else {
	    	foreach my $tag_elem (keys %{$xml_ref->{'photo'}->{'tags'}->{'tag'}}) {	
	            push (@tags, $xml_ref->{'photo'}->{'tags'}->{'tag'}->{$tag_elem}->{'raw'});
	        }
	    }
	    $tag = join(",", @tags);
	    $image_ref->{$photo_id}->{'title'} = $title;
	    $image_ref->{$photo_id}->{'tags'} = $tag;
	     
	} else {
	    print "Error fetching photo info from $url: $!\n";
	}
}

#
# Get photo URLs
#
sub get_photo_urls {
	
	my (@photos_ids) = @_;

	my $content = "";

        foreach my $photo (@photo_ids) {
		my $url = $flickr_photo_url_part1.$photo.$flickr_photo_url_part2;
		print "Fetching \n";
		print "-- Photo URL api: $url\n";
	
		my $response = $lwp->get($url);

                if ($response->is_success) {
                    $content = $response->decoded_content;
		    #print Dumper($content);
		    my $ref = XMLin($content, ForceArray=>["size"]);
		    #print Dumper($ref);
	
		    #
		    # Get photo title and info
		    #
		    &get_photo_info($photo);		    

		    #
		    # Pick the photo URL for the medium size image
		    #
		    foreach my $size (@{$ref->{'sizes'}->{'size'}}) {
			if ($size->{'label'} eq "Medium 640") {
				$image_ref->{$photo}->{'source_url'} = $size->{'source'};
			}
                    }
		   
		    #
		    # Update the photo URL's in our DB
		    #
		    update_photo_urls($photo);		
		} else {	
		    print "Error getting response from $url: $!\n";
		}
	}	
		
	

}

sub update_photo_urls {
  
	my ($photo_id) = @_;
        my $sth;

	print "-- Photo id : $photo_id\n";
	print "-- Source URL: $image_ref->{$photo_id}->{'source_url'}\n";
	print "-- Tags : $image_ref->{$photo_id}->{'tags'}\n";
	print "-- Title: $image_ref->{$photo_id}->{'title'}\n";

        eval {
                $sth = $dbh->prepare(qq{
                        INSERT INTO photo (photo_id,url,tags,title) VALUES (?,?,?,?)
                });
                $sth->execute($photo_id,$image_ref->{$photo_id}->{'source_url'}, $image_ref->{$photo_id}->{'tags'}, $image_ref->{$photo_id}->{'title'});
        };
        if ($@) {
                print "Error while running query: $dbh->errstr\n";
        }
    

} 
$dbh = &connect_db();	
@photo_ids = &get_flickr_photo_id($dbh, $get_flickr_photo_id_qry);

#
# test data 
#
#@photo_ids = splice(@photo_ids, 0,2);
#@photo_ids = ("10741493314");
#@photo_ids = ("10733207674");
get_photo_urls (@photo_ids);
