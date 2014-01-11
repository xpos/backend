#!/usr/bin/perl

use strict;
use Data::Dumper;
use DBI;

my $dbh = "";
my $photo_has_exif = {};

$dbh = connect_db();
get_aperture_val();

while (my ($id, $old_ap) = each %{$photo_has_exif}) {
	my $new_ap = normalize_aperture($old_ap);
	update_norm_aperture($id, $old_ap, $new_ap);
	
}

#
# Normalize aperture to remove f/ from f/2.8 (e.g) 
#
sub normalize_aperture {
	
	my ($ap_from_db) = @_;

	my $ap = "";
	
	#
	# Match for one or more numbers before decimal,
	# atleast one number after decimal,
	# no limit on atmost values after decimal 
	# (although it's likely to be only 1 after decimal)
	# 
	if ($ap_from_db =~ /(.*?)(\d+\.\d{1,})$/) {
		$ap = $2;
	} else {
		$ap = $ap_from_db;
	}
	return $ap;
}

#
# Connect to DB
#
sub connect_db {

        eval {
                $dbh = DBI->connect('dbi:mysql:xpos','','') or die "Connection Error: $DBI::errstr\n";
        };
        if ($@) {
                die "Unable to connect to DB : $@\n";
        }
        return $dbh;
}

#
# Get aperture values
#
sub get_aperture_val {
	
	my $query = "SELECT id, aperture from photo_has_exif";
	
	my $sth;
	eval {
                $sth = $dbh->prepare($query);
                $sth->execute();
		while (my ($id, $aperture) = $sth->fetchrow_array()) {
			$photo_has_exif->{$id} = $aperture;
		}
        };
        if ($@) {
                print "Error while running $query: $DBI::errstr: $!\n";
        }

}

#
# Update photo_has_exif with the normalized aperture value
#
sub update_norm_aperture {

	my ($photo_id, $old_ap, $norm_ap) = @_;
	
	my $sth = "";
	my $query = "UPDATE photo_has_exif set norm_aperture=\'$norm_ap\' WHERE id=\'$photo_id\' and aperture=\'$old_ap\'";
	print "Query: $query\n";
	eval {
		$sth = $dbh->prepare($query);
		$sth->execute();
		$sth->finish();
	};
	if ($@) {
		print "Error while running $query: $@\n";
	}
	
}
