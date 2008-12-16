include <mii.h>
include <mach.h>
include <fset.h>

# CAM_INIT_READ_PIXELS and READ_PIXELS -- Read pixel data with record buffering
# and data type conversion.  The input data must meet the MII standard
# except for possibly having the least significant byte first.
#
# Read data in records of len_record and convert to the specified IRAF
# data type.  Successive calls of cam_read_pixels returns the next npix pixels.
# Read_pixels returns EOF or the number of pixels converted.
# Cam_init_read_pixels must be called before cam_read_pixels.
#
# Error conditions are:
# 1. A short input record
# 2. Error in converting the pixels by miiup.
#
# This routine is based on the MII unpack routine which is machine dependent.
# The bitpix must correspond to an MII type.  If the lsbf (least significant
# byte first) flag is YES then the pixels do not satisfy the MII standard.
# In this case the bytes are first swapped into most significant byte first
# before the MII unpack routine is called.
#
# This version has been modified for the CAMERA format in that byte data
# is also swapped if lsbf = YES and a new record is read if only a
# partial line of data is in the buffer.

int procedure cam_init_read_pixels (npix_record, bitpix, spp_type)

long	npix_record	# Number of pixels per input record
int	bitpix		# Bits per pixel (must correspond to an MII type)
int	spp_type	# SPP data type to be returned

# entry cam_read_pixels (fd, buffer, npix)
int	cam_read_pixels
int	fd		# Input file descriptor
char	buffer[1]	# Output buffer
int	npix		# Number of pixels to read

int	ty_mii, ty_spp
int	npix_rec, nch_rec, sz_rec, nchars, len_mii
int	i, n, ip, op
int	swap
pointer	mii, spp

long	read()
int	sizeof()
size_t	miipksize()

include "rcamera.com"

errchk	miipksize, mfree, malloc, read, miiup
data	mii/NULL/, spp/NULL/


begin
	swap = lsbf
	ty_mii = bitpix
	ty_spp = spp_type
	npix_rec = npix_record
	nch_rec = npix_rec * sizeof (ty_spp)

	len_mii = miipksize (npix_rec, ty_mii)
	sz_rec = len_mii

	if (mii != NULL)
	    call mfree (mii, TY_CHAR)
	call malloc (mii, len_mii, TY_CHAR)

	if (spp != NULL)
	    call mfree (spp, TY_CHAR)
	call malloc (spp, nch_rec, TY_CHAR)

	ip = nch_rec
	return (OK)

entry	cam_read_pixels (fd, buffer, npix)

	op = 0
	nchars = npix * sizeof (ty_spp)
	repeat {

	    # If data is exhausted read the next record

	    if (ip + nchars > nch_rec) {   # Modified for CAMERA data

		# flush the tape buffers, only needed to handle
		# camera tapes created with 7-to-9 conversions
		if (tape == YES)
		    call fseti (fd, F_CANCEL, YES)

		# Read a data record
		i = read (fd, Memc[mii], sz_rec)
		if (i == EOF)
		    return (EOF)
	        else if ( i < sz_rec - SZ_INT + 1)
		    call error (0, "Short record encountered")

		# Convert from MII format to SPP format
		if (swap == YES)
		    switch (ty_mii) {

		    # 			Modified for CAMERA data	#
		    case MII_BYTE:					#
			call bswap2 (Memc[mii], 1, Memc[mii], 1,	#
				sz_rec * SZB_CHAR)			#

		    case MII_SHORT:
			call bswap2 (Memc[mii], 1, Memc[mii], 1,
				sz_rec * SZB_CHAR)
		    case MII_LONG:
			call bswap4 (Memc[mii], 1, Memc[mii], 1,
				sz_rec * SZB_CHAR)
		    }

		call miiupk (Memc[mii], Memc[spp], npix_rec, ty_mii, ty_spp)

		ip = 0
	    }

	    n = min (nch_rec - ip, nchars - op)
	    call amovc (Memc[spp + ip], buffer[1 + op], n)
	    ip = ip + n
	    op = op + n

	} until (op == nchars)

	return (npix)
end
