#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;
use XML::Simple;
use LWP::UserAgent;



my $get_cameras_qry = 'select id,brand_id,name from camera_brand';

my $dbh;
my $camera_brand = {};
my $brand_details_url_part1 = 'http://api.flickr.com/services/rest/?method=flickr.cameras.getBrandModels&api_key=fb548dbab5ada2c868d63d47e8866439&brand=';
my $brand_details_url_part2 = '&format=rest';

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

sub get_cameras {
	
	my ($db, $qry) = @_;

	my $sth = $db->prepare($qry);
	$sth->execute();
	while (my ($id, $brand_id, $brand_name) = $sth->fetchrow_array) {
		$camera_brand->{$brand_id} = $id.",".$brand_name;
	}
	return $camera_brand;
}

sub get_camera_brand_models {
	
	my ($db, $camera_brand) = @_;

	#$camera_brand = undef;
	#$camera_brand->{'hp'} = "20,HP"; #,Nikon";
	#$camera_brand->{'google'} = "39,Google";
	#$camera_brand->{'nikon'} = "2,Nikon";

	my %cam_br = %{$camera_brand};
	my $content = "";


	while (my ($key, $value) = each %cam_br ) {
		print "Camera brand id: $key, id,name : $value\n";
		
		my ($br_id, $br_name) = split(",", $value);
		my $url = $brand_details_url_part1."$key".$brand_details_url_part2;
		
		my $response = $lwp->get($url);
		
		if ($response->is_success) {
       		    $content = $response->decoded_content;
		
		    #print Dumper($content);
		    my $ref = XMLin($content,ForceArray=>["camera"]);
		    #print "--" x 10 ."\n";
		    #print Dumper($ref);
		    #print "--" x 10 ."\n";
		    delete $ref->{'stat'};
		    while ( my ($k, $v) = each (%{$ref})) {
			my $res_brand_id;
			my $brand_id;

			if (exists $v->{'brand'}) {
				
				$res_brand_id = $v->{'brand'};
				#$brand_id = $cam_br{$res_brand_id};
				$brand_id = $res_brand_id;

				my $model_id;
				my $model_lcd;
				my $model_memory_type;
				my $model_megapixels;
				my $model_small_image;
				my $model_large_image;
				my $model_zoom;

			        foreach my $model (keys %{$v->{'camera'}}) {
					#print Dumper ($v);	
					if (exists $v->{'camera'}->{$model}->{'id'}) {
						$model_id = $v->{'camera'}->{$model}->{'id'};
					}
					$model_lcd = $v->{'camera'}->{$model}->{'details'}->{'lcd_screen_size'};
					$model_memory_type = $v->{'camera'}->{$model}->{'details'}->{'memory_type'};
					$model_megapixels = $v->{'camera'}->{$model}->{'details'}->{'megapixels'};
					$model_zoom = $v->{'camera'}->{$model}->{'details'}->{'zoom'};
					$model_small_image = $v->{'camera'}->{$model}->{'images'}->{'small'};
					$model_large_image = $v->{'camera'}->{$model}->{'images'}->{'large'};
				
					print "===" x 20 ."\n";	
					print "Model details to insert :>>>>>>>\n";
					print "Brand id : $brand_id\n";
					print "Model Name: $model\n";
					print "Model id : $model_id\n";
					print "LCD: $model_lcd\n";
					print "Memory type: $model_memory_type\n";
					print "Megapixels : $model_megapixels\n";
					print "Small Image: $model_small_image\n";
					print "Large Image : $model_large_image\n";
					print "===" x 20 ."\n\n";
					update_camera_brand_models($db, $brand_id, $model, $model_megapixels, $model_lcd, $model_memory_type, $model_zoom, $model_small_image, $model_large_image);
			    	}
		    	}
		    }

    		}
    		else {
       		    warn "Error getting $url from LWP: ".Dumper($response->status_line)."\n";
    		}	
	}
}

sub update_camera_brand_models {
	
	my ($dbh, $brand_id, $model_name, $model_megapixels, $model_lcd, $model_memory_type, $model_zoom, $model_small_image, $model_large_image) = @_;

	my $sth;

	eval {
		$sth = $dbh->prepare(qq{
			INSERT INTO camera_brand_model (brand_id, name, megapixels, lcd_screen_size, memory_type, zoom, small_image, large_image) VALUES (?,?,?,?,?,?,?,?)
		});
		$sth->execute($brand_id,$model_name, $model_megapixels,$model_lcd,$model_memory_type,$model_zoom,$model_small_image, $model_large_image);
	};
	if ($@) {
        	print "Error while running query: $dbh->errstr\n";
	}
}

$dbh = &connect_db();	
$camera_brand = &get_cameras($dbh, $get_cameras_qry);

#print Dumper($camera_brand);
&get_camera_brand_models ($dbh,$camera_brand);
