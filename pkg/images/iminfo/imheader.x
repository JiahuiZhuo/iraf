# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<error.h>
include	<ctype.h>
include	<imhdr.h>
include	<imio.h>
include	<time.h>

define	SZ_DIMSTR	(IM_MAXDIM*4)
define	SZ_MMSTR	40
define	USER_AREA	Memc[($1+IMU-1)*SZ_STRUCT + 1]
define	LMARGIN		4


# IMHEADER -- Read contents of an image header and print on STDOUT.

procedure t_imheader()

int	list, nimages
pointer	sp, template, image
bool	long_format, user_fields
int	imtopen(), imtgetim()
bool	clgetb()

begin
	call smark (sp)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (template, SZ_LINE, TY_CHAR)

	call clgstr ("images", Memc[template], SZ_LINE)
	list = imtopen (Memc[template])

	long_format = clgetb ("longheader")
	user_fields = clgetb ("userfields")
	nimages = 0

	while (imtgetim (list, Memc[image], SZ_FNAME) != EOF) {
	    nimages = nimages + 1
	    if (long_format && nimages > 1)
		call putci (STDOUT, '\n')
	    iferr (call imphdr (STDOUT, Memc[image], long_format, user_fields))
		call erract (EA_WARN)
	    call flush (STDOUT)
	}

	call imtclose (list)
end


# IMPHDR -- Print the contents of an image header.

procedure imphdr (fd, image, long_format, user_fields)

int	fd
char	image[ARB]
bool	long_format
bool	user_fields

int	hi, i
pointer	im, sp, ctime, mtime, ldim, pdim, hgm, title, lbuf, ip
int	access(), gstrcpy(), stropen(), getline(), strlen(), stridxs()
pointer	immap()
errchk	im_fmt_dimensions, immap, access, stropen, getline
define	done_ 91

begin
	# Allocate automatic buffers.
	call smark (sp)
	call salloc (ctime, SZ_TIME,   TY_CHAR)
	call salloc (mtime, SZ_TIME,   TY_CHAR)
	call salloc (ldim,  SZ_DIMSTR, TY_CHAR)
	call salloc (pdim,  SZ_DIMSTR, TY_CHAR)
	call salloc (title, SZ_LINE,   TY_CHAR)
	call salloc (lbuf,  SZ_LINE,   TY_CHAR)

	im = immap (image, READ_ONLY, 0)

	# Format subscript strings, date strings, mininum and maximum
	# pixel values.

	call im_fmt_dimensions (im, Memc[ldim], SZ_DIMSTR, IM_LEN(im,1))
	call im_fmt_dimensions (im, Memc[pdim], SZ_DIMSTR, IM_PHYSLEN(im,1))
	call cnvtime (IM_CTIME(im), Memc[ctime], SZ_TIME)
	call cnvtime (IM_MTIME(im), Memc[mtime], SZ_TIME)

	# Strip any trailing whitespace from the title string.
	ip = title + gstrcpy (IM_TITLE(im), Memc[title], SZ_LINE) - 1
	while (ip >= title && IS_WHITE(Memc[ip]) || Memc[ip] == '\n')
	    ip = ip - 1
	Memc[ip+1] = EOS

	# Begin printing image header.
	call fprintf (fd, "%s%s[%s]: %s\n")
	    call pargstr (IM_NAME(im))
	    call pargstr (Memc[ldim])
	    call pargtype (IM_PIXTYPE(im))
	    call pargstr (Memc[title])

	# All done if not long format.
	if (! long_format)
	    goto done_

	call fprintf (fd, "%4w%s bad pixels, %s histogram, min=%s, max=%s%s\n")
	    if (IM_NBPIX(im) == 0)			# num bad pixels
		call pargstr ("No")
	    else
		call pargl (IM_NBPIX(im))

	    hgm = IM_HGM(im)				# is hgm valid?
	    if (HGM_TIME(hgm) == 0)
		call pargstr ("no")
	    else if (HGM_TIME(hgm) < IM_MTIME(im))
		call pargstr ("old")
	    else
		call pargstr ("valid")

	    if (IM_LIMTIME(im) == 0) {			# min,max pixel values
		do i = 1, 2
		    call pargstr ("unknown")
		call pargstr ("")
	    } else {
		call pargr (IM_MIN(im))
		call pargr (IM_MAX(im))
		if (IM_LIMTIME(im) < IM_MTIME(im))
		    call pargstr (" (old)")
		else
		    call pargstr ("")
	    }

	call fprintf (fd,
	    "%4w%s storage mode, physdim %s, length of user area %d s.u.\n")
	    call pargstr ("Line")
	    call pargstr (Memc[pdim])
	    call pargi (IM_HDRLEN(im) - LEN_IMHDR)

	call fprintf (fd, "%4wCreated %s, Last modified %s\n")
	    call pargstr (Memc[ctime])			# times
	    call pargstr (Memc[mtime])

	call fprintf (fd, "%4wPixel file '%s' %s\n")
	    call pargstr (IM_PIXFILE(im))
	    if (access (IM_PIXFILE(im), 0, 0) == YES)
		call pargstr ("[ok]")
	    else
		call pargstr ("[NO PIXEL FILE]")

	# Print the history records.
	if (strlen (IM_HISTORY(im)) > 1) {
	    hi = stropen (IM_HISTORY(im), ARB, READ_ONLY)
	    while (getline (hi, Memc[lbuf]) != EOF) {
		call putline (fd, "    ")
		call putline (fd, Memc[lbuf])
		if (stridxs ("\n", Memc[lbuf]) == 0)
		    call putline (fd, "\n")
	    }
	    call close (hi)
	}

	if (user_fields)
	    call imh_print_user_area (fd, im)

done_
	call imunmap (im)
	call sfree (sp)
end


# IM_FMT_DIMENSIONS -- Format the image dimensions in the form of a subscript,
# i.e., "[nx,ny,nz,...]".

procedure im_fmt_dimensions (im, outstr, maxch, len_axes)

pointer	im
char	outstr[ARB]
int	maxch, i, fd, stropen()
long	len_axes[ARB]
errchk	stropen, fprintf, pargl

begin
	fd = stropen (outstr, maxch, NEW_FILE)

	call fprintf (fd, "[%d")
	    call pargl (len_axes[1])

	do i = 2, IM_NDIM(im) {
	    call fprintf (fd, ",%d")
		call pargl (len_axes[i])
	}

	call fprintf (fd, "]")
	call close (fd)
end


# PARGTYPE -- Convert an integer type code into a string, and output the
# string with PARGSTR to FMTIO.

procedure pargtype (dtype)

int	dtype

begin
	switch (dtype) {
	case TY_UBYTE:
	    call pargstr ("ubyte")
	case TY_BOOL:
	    call pargstr ("bool")
	case TY_CHAR:
	    call pargstr ("char")
	case TY_SHORT:
	    call pargstr ("short")
	case TY_USHORT:
	    call pargstr ("ushort")
	case TY_INT:
	    call pargstr ("int")
	case TY_LONG:
	    call pargstr ("long")
	case TY_REAL:
	    call pargstr ("real")
	case TY_DOUBLE:
	    call pargstr ("double")
	case TY_COMPLEX:
	    call pargstr ("complex")
	case TY_POINTER:
	    call pargstr ("pointer")
	case TY_STRUCT:
	    call pargstr ("struct")
	default:
	    call pargstr ("unknown datatype")
	}
end


# IMH_PRINT_USER_AREA -- Print the user area of the image, if nonzero length
# and it contains only ascii values.

procedure imh_print_user_area (out, im)

int	out			# output file
pointer	im			# image descriptor

pointer	sp, lbuf, ip
int	in, ncols, min_lenuserarea 
int	stropen(), getline(), envgeti()

begin
	call smark (sp)
	call salloc (lbuf, SZ_LINE, TY_CHAR)

	# Open user area in header.
	min_lenuserarea = (LEN_IMDES + IM_LENHDRMEM(im) - IMU) * SZ_STRUCT - 1
	in = stropen (USER_AREA(im), min_lenuserarea, READ_ONLY)
	ncols = envgeti ("ttyncols") - LMARGIN

	# Copy header records to the output, stripping any trailing
	# whitespace and clipping at the right margin.

	while (getline (in, Memc[lbuf]) != EOF) {
	    for (ip=lbuf;  Memc[ip] != EOS && Memc[ip] != '\n';  ip=ip+1)
		;
	    while (ip > lbuf && Memc[ip-1] == ' ')
		ip = ip - 1
	    if (ip - lbuf > ncols)
		ip = lbuf + ncols 
	    Memc[ip] = '\n'
	    Memc[ip+1] = EOS
	    
	    call putline (out, "    ")
	    call putline (out, Memc[lbuf])
	}

	call close (in)
	call sfree (sp)
end