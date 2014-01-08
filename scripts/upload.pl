#!/usr/bin/perl
#
# This script is responsible for uploading the user's image to a 
# tmp directory and then running exiftool to extract image exif 
# data.
#
# Author         dd/mm/yyyy      Comments
#
# bknathan       08/01/2014      Created

use strict;
use CGI;
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;
use Image::ExifTool ':Public';

#
# Set max upload limit
#
$CGI::POST_MAX = 1024 * 5000;
my $safe_filename_characters = "a-zA-Z0-9_.-";


#
# Set upload directory
#
my $upload_dir = "/home/images/htdocs/flickr_upload";

my $obj = new CGI;
my $filename = $obj->param("photo");

if (! $filename) {
	print $obj->header();
	print "There was a problem uploading your photo (try a smaller file).\n";
	exit;
}

#
# Get the filename, path and file extension
#
my ( $name, $path, $extension ) = fileparse ( $filename, '..*' );
$filename = $name . $extension;

#
# Convert spaces to "_"
#
$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;

#
# Match against the safe filename chars to check if it's untainted
#
if ( $filename =~ /^([$safe_filename_characters]+)$/ ) {
	$filename = $1;
} else {
	die "Filename contains invalid characters";
}

#
# Get the uploaded photo's filehandle
#
my $upload_filehandle = $obj->upload("photo");

#
# Save the file
#
open ( UPLOADFILE, ">$upload_dir/$filename" ) or die "$!";
binmode UPLOADFILE;

while ( <$upload_filehandle> ) {
	print UPLOADFILE;
}
close UPLOADFILE;

#
# Extract exif data from the uploaded file
#
my $file_to_exif = $upload_dir."/".$filename;
my $info = ImageInfo($file_to_exif);

#
# Get exif info from the uploaded file
#
my $exif = &_print_exif();

#
# Print response body
#
&_print_response($exif);

#
# Print exif info
#
sub _print_exif {

	my $exif_info = "";

	foreach (keys %$info) {
		$exif_info .=  "<p>$_ : $info->{$_}</p>";
	}
	return $exif_info;
}

#
# Actual Response body upon successful upload
#
sub _print_response {

my ($exif_info) = @_;
print $obj->header ( );
print <<END_HTML;
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Thanks!</title>
<style type="text/css">
img {border: none;}
</style>
</head>
<body>
<p>Thanks for uploading your photo!</p>
<p>Your photo: $filename has been uploaded successfully </p>
<p><img src="/flickr_upload/$filename" alt="Photo" height="300" width="300"/></p>
<p> $exif_info </p>
</body>
</html>
END_HTML

}


