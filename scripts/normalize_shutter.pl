#!/usr/bin/perl

use strict;
use Data::Dumper;
use DBI;

my $dbh = "";
my $photo_has_exif = {};

$dbh = connect_db();
get_shutter_val();

while (my ($id, $old_sh) = each %{$photo_has_exif}) {
	my $new_sh = normalize_shutter($old_sh);
	update_norm_shutter($id, $old_sh, $new_sh);
	
}

#
# Normalize shutter speed. Convert from:
#   a) 0.003 sec (1/290) to 1/290
#   b) 1/4000 sec to 1/4000
#   c) 400 to 1/400
#   d) do nothing on 1/400 
#
sub normalize_shutter {

        my ($sh_from_db) = @_;

        my $sh = "";

        #
        # Match for one or more numbers before decimal,
        # atleast one number after decimal,
        # no limit on atmost values after decimal 
        # (although it's likely to be only 1 after decimal)
        #
        if ($sh_from_db != 0) {

                # match string: 0.003 sec (1/290) 
                if ($sh_from_db =~ /(\d+\.\d{1,})\s(\w+)\s\((.*?)\)/) {
                        $sh = $3;
                }

                # match string : 1/4000 sec 
                elsif ($sh_from_db =~ /(.*?)\ssec/) {
                        $sh = $1;
                }

                # match string : 400
                elsif ($sh_from_db =~ /^(\d+)$/) {
                        $sh = "1/".$sh_from_db;
                }

                # match string : 1/400
                else {
                        $sh = $sh_from_db;
                }
        }
        return $sh;
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
# Get shutter values
#
sub get_shutter_val {
	
	my $query = "SELECT id, shutter_speed from photo_has_exif";
	
	my $sth;
	eval {
                $sth = $dbh->prepare($query);
                $sth->execute();
		while (my ($id, $shutter_speed) = $sth->fetchrow_array()) {
			$photo_has_exif->{$id} = $shutter_speed;
		}
        };
        if ($@) {
                print "Error while running $query: $DBI::errstr: $!\n";
        }

}

#
# Update photo_has_exif with the normalized shutter speed value
#
sub update_norm_shutter {

	my ($photo_id, $old_sh, $norm_sh) = @_;
	
	my $sth = "";
	my $query = "UPDATE photo_has_exif set norm_shutter=\'$norm_sh\' WHERE id=\'$photo_id\' and shutter_speed=\'$old_sh\'";
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
