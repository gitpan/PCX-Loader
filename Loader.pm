#!/usr/bin/perl	

# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
#

BEGIN {
	 $PCX::Loader::VERSION = "0.50";
}


package PCX::Loader;
	
	use strict;

	# Constructor. Loades PCX file into class.
	sub new {
		my $type	=	shift;
		my $self	=	{ 
			file    => $_[1]
		};
		my (@a,@b)=load_pcx($_[1]);
		$self->{image}=\@a;
		$self->{palette}=\@b;
		bless \%{$self}, $type;
	}

	# Returns a rectangular block defined by an array ref in the form of
	# 		[$x1,$y1,$x2,$y2]
	# Return value is an array ref
	sub get_block {
		no strict 'refs';
		my $self	=	shift;
		my $ref		=	shift;
		my ($x1,$y1,$x2,$y2)	=	@{$ref};
		my @block	=	();
		my $count	=	0;
		for my $x ($x1..$x2-1) {
			for my $y ($y1..$y2-1) {
				$block[$count++]	=	$self->get($x,$y);
			}
		}
		return \@block;
	}
			
	# Returns pixel at $x,$y
	sub get {
		my $self	=	shift;
		my ($x,$y)  =	(shift,shift);
		return $self->{image}->[$y*320+$x];
	}
	
	# Returns array of (r,g,b) value from palette index passed
	sub rgb {
		my $self	=	shift;
		my $color	=	shift;
		return ($self->{palette}->[$color]->{red},$self->{palette}->[$color]->{green},$self->{palette}->[$color]->{blue});
	}
		
	# Returns mean of (rgb) value of palette index passed
	sub avg {
		my $self	=	shift;
		my $color	=	shift;
		return intr(($self->{palette}->[$color]->{red}+$self->{palette}->[$color]->{green}+$self->{palette}->[$color]->{blue})/3);
	}
	
	# Loads and decompresses a PCX-format 320x200, 8-bit image file and returns 
	# two arrays, first is a 64000-byte long array, each element contains a palette
	# index, and the second array is a 255-byte long array, each element is a hash
	# ref with the keys 'red', 'green', and 'blue', each key contains the respective color
	# component for that color index in the palette.
	sub load_pcx {
		shift if(substr($_[0],0,4) eq 'AI::'); 
		
		# open the file
		open(FILE, "$_[0]");
		binmode(FILE);
		
		my $tmp;
		my @image;
		my @palette;
		my $data;
		
		# Read header
		read(FILE,$tmp,128);
		
		# load the data and decompress into buffer
		my $count=0;
		
		while($count<320*200) {
		     # get the first piece of data
		     read(FILE,$data,1);
	         $data=ord($data);
	         
		     # is this a rle?
		     if ($data>=192 && $data<=255) {
		        # how many bytes in run?
		        my $num_bytes = $data-192;
		
		        # get the actual $data for the run
		        read(FILE, $data, 1);
				$data=ord($data);
		        # replicate $data in buffer num_bytes times
		        while($num_bytes-->0) {
	            	$image[$count++] = $data;
		        } # end while
		     } else {
		        # actual $data, just copy it into buffer at next location
		        $image[$count++] = $data;
		     } # end else not rle
		}
		
		# move to end of file then back up 768 bytes i.e. to begining of palette
		seek(FILE,-768,2);
		
		# load the pallete into the palette
		for my $index (0..255) {
		    # get the red component
		    read(FILE,$tmp,1);
		    $palette[$index]->{red}   = ($tmp>>2);
		
		    # get the green component
		    read(FILE,$tmp,1);
			$palette[$index]->{green} = ($tmp>>2);
		
		    # get the blue component
		    read(FILE,$tmp,1);
			$palette[$index]->{blue}  = ($tmp>>2);
		
		}
		
		close(FILE);
		
		return @image,@palette;
	}

	# Rounds a floating-point to an integer with int() and sprintf()
	sub intr  {
    	shift if(substr($_[0],0,4) eq 'AI::');
      	try   { return int(sprintf("%.0f",shift)) }
      	catch { return 0 }
	}
    
1;

__END__

=head1 NAME

PCX::Loader - Loads 320x200 8-bit PCX-format graphics.

=head1 SYNOPSIS

	my $pcx = new PCX::Loader('face.pcx');

=head1 METHODS

=item new PCX::Loader($filename);

This is a treat... this routine will load a PCX-format file (yah, I know ... ancient 
format ... but it is the only one I could find specs for to write it in Perl. If 
anyone can get specs for any other formats, or could write a loader for them, I 
would be very grateful!) Anyways, a PCX-format file that is exactly 320x200 with 8 bits 
per pixel, with pure Perl. It returns a blessed refrence to a PCX::Loader object.


=item $pcx->{image}

This is an array refrence to the entire image. The array containes exactly 64000 elements, each
element contains a number corresponding into an index of the palette array, details below.



=item $pcx->{palette}

This is an array ref to an AoH (array of hashes). Each element has the following three keys:
	
	$pcx->{palette}->[0]->{red};
	$pcx->{palette}->[0]->{green};
	$pcx->{palette}->[0]->{blue};

Each is in the range of 0..63, corresponding to their named color component.



=item $pcx->get_block($array_ref);

Returns a rectangular block defined by an array ref in the form of:
	
	[$left,$top,$right,$bottom]

These must be in the range of 0..319 for $left and $right, and the range of 0..199 for
$top and $bottom. The block is returned as an array ref with horizontal lines in sequental order.
I.e. to get a pixel from [2,5] in the block, and $left-$right was 20, then the element in 
the array ref containing the contents of coordinates [2,5] would be found by [5*20+2] ($y*$width+$x).
    
	print $pcx->get_block(0,0,20,50)->[5*20+2];

This would print the contents of the element at block coords [2,5].



=item $pcx->get($x,$y);

Returns the value of pixel at image coordinates $x,$y.
$x must be in the range of 0..319 and $y must be in the range of 0..199.



=item $pcx->rgb($index);

Returns a 3-element array (not array ref) with each element corresponding to the red, green, or
blue color components, respecitvely.



=item $pcx->avg($index);	

Returns the mean value of the red, green, and blue values at the palette index in $index.

	

=head1 BUGS

This is the beta release of C<AI::NeuralNet::Mesh>, and that holding true, I am sure 
there are probably bugs in here which I just have not found yet. If you find bugs in this module, I would 
appreciate it greatly if you could report them to me at F<E<lt>jdb@wcoil.comE<gt>>,
or, even better, try to patch them yourself and figure out why the bug is being buggy, and
send me the patched code, again at F<E<lt>jdb@wcoil.comE<gt>>. 


=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<PCX::Loader> module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

$Id: PCX::Loader.pm, v0.50 2000/22/12 00:01:27 josiah Exp $


=head1 DOWNLOAD

You can always download the latest copy of AI::NeuralNet::Mesh
from http://www.josiah.countystart.com/modules/AI/cgi-bin/rec.pl?pcx-loader:pod

