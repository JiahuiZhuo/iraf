# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<imhdr.h>
include <pkg/gtools.h>
include	<error.h>

define	MAXBUF	(512*100)		# Maximum number of pixels per block


# FIT1D -- Fit a function to image lines or columns and output an image
# consisting of the fit, the difference, or the ratio.  The fitting parameters
# may be set interactively using the icfit package.

procedure t_fit1d ()

pointer	listin				# Input image list
pointer	listout				# Output image list
bool	interactive			# Interactive?

char	sample[SZ_LINE]			# Sample ranges
int	naverage			# Sample averaging size
char	function[SZ_LINE]		# Curve fitting function
int	order				# Order of curve fitting function
real	low_reject, high_reject		# Rejection thresholds
int	niterate			# Number of rejection iterations
real	grow				# Rejection growing radius

int	axis				# Image axis to fit
int	ntype				# Type of output
char	input[SZ_LINE]			# Input image
char	output[SZ_FNAME]		# Output image
pointer	in, out				# IMIO pointers
pointer	ic				# ICFIT pointer
pointer	gt				# GTOOLS pointer

bool	same, clgetb()
int	imtgetim(), imtlen(), strdic()
pointer	imtopen(), gt_init()
int	clgeti()
real	clgetr()

begin
	# Get input and output lists and check that the number of images
	# are the same.

	call clgstr ("input", input, SZ_LINE)
	listin = imtopen (input)
	call clgstr ("output", input, SZ_LINE)
	listout = imtopen (input)
	if (imtlen (listin) != imtlen (listout)) {
	    call imtclose (listin)
	    call imtclose (listout)
	    call error (0, "Input and output image lists do not match")
	}

	# Get task parameters.

	axis = clgeti ("axis")
	call clgstr ("type", input, SZ_LINE)
	call clgstr ("sample", sample, SZ_LINE)
	naverage = clgeti ("naverage")
	call clgstr ("function", function, SZ_LINE)
	order = clgeti ("order")
	low_reject = clgetr ("low_reject")
	high_reject = clgetr ("high_reject")
	niterate = clgeti ("niterate")
	grow = clgetr ("grow")
	interactive = clgetb ("interactive")

 	# Decode the output type and initialize the curve fitting package.

	ntype = strdic (input, input, SZ_LINE, "|fit|difference|ratio|")
	if (ntype == 0)
	    call error (0, "Unknown output type")

	# Set the ICFIT pointer structure.
	call ic_open (ic)
	call ic_pstr (ic, "sample", sample)
	call ic_puti (ic, "naverage", naverage)
	call ic_pstr (ic, "function", function)
	call ic_puti (ic, "order", order)
	call ic_putr (ic, "low", low_reject)
	call ic_putr (ic, "high", high_reject)
	call ic_puti (ic, "niterate", niterate)
	call ic_putr (ic, "grow", grow)
	call ic_pstr (ic, "ylabel", "")

	gt = gt_init()
	call gt_sets (gt, GTTYPE, "line")

	# Fit the lines in each input image.

	while ((imtgetim (listin, input, SZ_LINE) != EOF) &&
	    (imtgetim (listout, output, SZ_FNAME) != EOF)) {

	    iferr (call f1d_immap (input, output, ntype, in, out, same)) {
		call erract (EA_WARN)
		next
	    }
	    call f1d_fit1d (in, out, ic, gt, input, axis, ntype, interactive)
	    call imunmap (in)
	    if (!same)
		call imunmap (out)
	}

	call ic_closer (ic)
	call gt_free (gt)
	call imtclose (listin)
	call imtclose (listout)
end


# F1D_FIT1D -- Given the image descriptor determine the fitting function
# for each line or column and create an output image.  If the interactive flag
# is set then set the fitting parameters interactively.

procedure f1d_fit1d (in, out, ic, gt, title, axis, ntype, interactive)

pointer	in				# IMIO pointer for input image
pointer	out				# IMIO pointer for output image
pointer	ic				# ICFIT pointer
pointer	gt				# GTOOLS pointer
char	title[ARB]			# Title
int	axis				# Image axis to fit
int	ntype				# Type of output
bool	interactive			# Interactive?

size_t	sz_val
char	graphics[SZ_FNAME]		# Graphics device
int	i, nx, new
real	div
pointer	cv, gp, sp, x, wts, indata, outdata

int	f1d_getline(), f1d_getdata(), strlen()
real	cveval()
pointer	gopen()

begin
	# Error check.

	if (IM_NDIM (in) > 2)
	    call error (0, "Image dimensions > 2 are not implemented")
	if (axis > IM_NDIM (in))
	    call error (0, "Axis exceeds image dimension")

	# Allocate memory for curve fitting.

	nx = IM_LEN (in, axis)
	call smark (sp)
	sz_val = nx
	call salloc (x, sz_val, TY_REAL)
	call salloc (wts, sz_val, TY_REAL)

	do i = 1, nx
	    Memr[x+i-1] = i
	call amovkr (1., Memr[wts], nx)

	call ic_putr (ic, "xmin", Memr[x])
	call ic_putr (ic, "xmax", Memr[x+nx-1])

	# If the interactive flag is set then use icg_fit to set the
	# fitting parameters.  Get_fitline returns EOF when the user
	# is done.  The weights are reset since the user may delete
	# points.

	if (interactive) {
	    call clgstr ("graphics", graphics, SZ_FNAME)
	    gp = gopen (graphics, NEW_FILE, STDGRAPH)

	    i = strlen (title)
	    indata = NULL
	    while (f1d_getline (ic, gt, in, axis, title, indata) != EOF) {
		title[i + 1] = EOS
	        call icg_fit (ic, gp, "cursor", gt, cv, Memr[x], Memr[indata],
		    Memr[wts], nx)
		call amovkr (1., Memr[wts], nx)
	    }
	    call mfree (indata, TY_REAL)
	    call gclose (gp)
	}

	# Loop through the input image and create an output image.

	new = YES

	while (f1d_getdata (in, out, axis, MAXBUF, indata, outdata) != EOF) {

	    call ic_fit (ic, cv, Memr[x], Memr[indata], Memr[wts],
		nx, new, YES, new, new)
	    new = NO

	    # Be careful because the indata and outdata buffers may be the same.
	    switch (ntype) {
	    case 1:
	        call cvvector (cv, Memr[x], Memr[outdata], nx)
	    case 2:
		do i = 0, nx-1
		    Memr[outdata+i] = Memr[indata+i] - cveval (cv, Memr[x+i])
	    case 3:
		do i = 0, nx-1 {
		    div = cveval (cv, Memr[x+i])
		    if (abs (div) < 1E-20)
			div = 1
		    Memr[outdata+i] = Memr[indata+i] / div
		}
	    }
	}

	call cvfree (cv)
	call sfree (sp)
end


# F1D_IMMAP -- Map images for fit1d.

procedure f1d_immap (input, output, ntype, in, out, same)

char	input[ARB]		# Input image
char	output[ARB]		# Output image
int	ntype			# Type of fit1d output
pointer	in			# Input IMIO pointer
pointer	out			# Output IMIO pointer
bool	same			# Same image?

long	lg_val
size_t	sz_val
int	i
pointer	sp, iroot, isect, oroot, osect, line, data

bool	streq()
int	imaccess(), impnlr()
pointer	immap()
errchk	immap

begin
	# Get the root name and section of the input image.

	call smark (sp)
	sz_val = SZ_FNAME
	call salloc (iroot, sz_val, TY_CHAR)
	call salloc (isect, sz_val, TY_CHAR)
	call salloc (oroot, sz_val, TY_CHAR)
	call salloc (osect, sz_val, TY_CHAR)

	call imgimage (input, Memc[iroot], SZ_FNAME)
	call imgsection (input, Memc[isect], SZ_FNAME)
	call imgimage (output, Memc[oroot], SZ_FNAME)
	call imgsection (output, Memc[osect], SZ_FNAME)
	same = streq (Memc[iroot], Memc[oroot])

	# If the output image is not accessible then create it as a new copy
	# of the full input image and initialize according to ntype.

	if (imaccess (output, READ_WRITE) == NO) {
	    in = immap (Memc[iroot], READ_ONLY, 0)
	    out = immap (Memc[oroot], NEW_COPY, in)
	    IM_PIXTYPE(out) = TY_REAL

	    sz_val = IM_MAXDIM
	    call salloc (line, sz_val, TY_LONG)
	    lg_val = 1
	    sz_val = IM_MAXDIM
	    call amovkl (lg_val, Meml[line], sz_val)

	    switch (ntype) {
	    case 1, 2:
	        while (impnlr (out, data, Meml[line]) != EOF)
	            call aclrr (Memr[data], IM_LEN(out, 1))
	    case 3:
	        while (impnlr (out, data, Meml[line]) != EOF)
	            call amovkr (1., Memr[data], IM_LEN(out, 1))
	    }

	    call imunmap (in)
	    call imunmap (out)
	}

	# Map the input and output images.  If the output image has a section
	# then use it.  If the input image has a section and the output image
	# does not then add the image section to the output image.  Finally
	# check the input and output images have the same size.

	in = immap (input, READ_ONLY, 0)

	if (Memc[isect] != EOS && Memc[osect] == EOS) {
	    call sprintf (Memc[osect], SZ_FNAME, "%s%s")
	        call pargstr (Memc[oroot])
	        call pargstr (Memc[isect])
	} else
	    call strcpy (output, Memc[osect], SZ_FNAME)

	if (streq (input, Memc[osect])) {
	    call imunmap (in)
	    in = immap (input, READ_WRITE, 0)
	    out = in
	} else
	    out = immap (Memc[osect], READ_WRITE, 0)

	do i = 1, IM_NDIM(in)
	    if (IM_LEN(in, i) != IM_LEN(out, i)) {
		call imunmap (in)
		if (!same)
		    call imunmap (out)
		call sfree (sp)
		call error (0, "Input and output images have different sizes")
	    }

	call sfree (sp)
end


# F1D_GETDATA -- Get a line of image data.

int procedure f1d_getdata (in, out, axis, maxbuf, indata, outdata)

pointer	in			# Input IMIO pointer
pointer	out			# Output IMIO pointer
int	axis			# Image axis
int	maxbuf			# Maximum buffer size for column axis
pointer	indata			# Input data pointer
pointer	outdata			# Output data pointer

size_t	sz_val
int	i, index, last_index, col1, col2, nc, ncols, nlines, ncols_block
pointer	inbuf, outbuf, ptr
pointer	imgl1r(), impl1r(), imgl2r(), impl2r(), imgs2r(), imps2r()
data	index/0/

begin
	# Increment to the next image vector.

	index = index + 1

	# Initialize for the first vector.

	if (index == 1) {
	    ncols = IM_LEN (in, 1)
	    if (IM_NDIM (in) == 1)
		nlines = 1
	    else
		nlines = IM_LEN (in, 2)

	    switch (axis) {
	    case 1:
		last_index = nlines
	    case 2:
		last_index = ncols
	        ncols_block = max (1, min (ncols, maxbuf / nlines))
		col2 = 0

	        sz_val = nlines
	        call malloc (indata, sz_val, TY_REAL)
	        call malloc (outdata, sz_val, TY_REAL)
	    }
	}

	# Finish up if the last vector has been done.

	if (index > last_index) {
	    if (axis == 2) {
	        ptr = outbuf + index - 1 - col1
	        do i = 1, nlines {
		    Memr[ptr] = Memr[outdata+i-1]
		    ptr = ptr + nc
	        }

	        call mfree (indata, TY_REAL)
	        call mfree (outdata, TY_REAL)
	    }

	    index = 0
	    return (EOF)
	}

	# Get the next image vector.

	switch (axis) {
	case 1:
	    if (IM_NDIM (in) == 1) {
		indata = imgl1r (in)
		outdata = impl1r (out)
	    } else {
		indata = imgl2r (in, index)
		outdata = impl2r (out, index)
	    }
	case 2:
	    if (index > 1) {
		ptr = outbuf + index - 1 - col1
		do i = 1, nlines {
		    Memr[ptr] = Memr[outdata+i-1]
		    ptr = ptr + nc
		}
	    }

	    if (index > col2) {
		col1 = col2 + 1
		col2 = min (ncols, col1 + ncols_block - 1)
		inbuf = imgs2r (in, col1, col2, 1, nlines)
		outbuf = imps2r (out, col1, col2, 1, nlines)
		nc = col2 - col1 + 1
	    }

	    ptr = inbuf + index - col1
	    do i = 1, nlines {
		Memr[indata+i-1] = Memr[ptr]
		ptr = ptr + nc
	    }
	}

	return (index)
end


# F1D_GETLINE -- Get image data to be fit interactively.  Return EOF
# when the user enters EOF or CR.  Default is 1 and the out of bounds
# requests are silently limited to the nearest in edge.

int procedure f1d_getline (ic, gt, im, axis, title, data)

pointer	ic			# ICFIT pointer
pointer	gt			# GTOOLS pointer
pointer	im			# IMIO pointer
int	axis			# Image axis
char	title[ARB]		# Title
pointer	data			# Image data

size_t	sz_val
pointer	x
char	line[SZ_LINE]
int	i, j, stat, imlen
int	getline(), nscan()
pointer	imgl1r()
data	stat/EOF/

begin
	# If the image is one dimensional do not prompt.

	if (IM_NDIM (im) == 1) {
	    if (stat == EOF) {
		call sprintf (title, SZ_LINE, "%s\n%s")
	    	    call pargstr (title)
	    	    call pargstr (IM_TITLE(im))
		call gt_sets (gt, GTTITLE, title)
		call mfree (data, TY_REAL)
		sz_val = IM_LEN(im, 1)
		call malloc (data, sz_val, TY_REAL)
		call amovr (Memr[imgl1r(im)], Memr[data], IM_LEN(im, 1))
		stat = OK
	    } else
		stat = EOF

	    return (stat)
	}

	# If the image is two dimensional prompt for the line or column.

	switch (axis) {
	case 1:
	    imlen = IM_LEN (im, 2)
	    call sprintf (title, SZ_LINE, "%s: Fit line =")
	        call pargstr (title)
	case 2:
	    imlen = IM_LEN (im, 1)
	    call sprintf (title, SZ_LINE, "%s: Fit column =")
	        call pargstr (title)
	}

	call printf ("%s ")
	    call pargstr (title)
	call flush (STDOUT)

	if (getline(STDIN, line) == EOF)
	    return (EOF)

	call sscan (line)
	call gargi (i)
	call gargi (j)

	switch (nscan()) {
	case 0:
	    stat = EOF
	    return (stat)
	case 1:
	    i = max (1, min (imlen, i))
	    j = i
	case 2:
	    i = max (1, min (imlen, i))
	    j = max (1, min (imlen, j))
	}

	call sprintf (title, SZ_LINE, "%s %d - %d\n%s")
	    call pargstr (title)
	    call pargi (i)
	    call pargi (j)
	    call pargstr (IM_TITLE(im))

	call gt_sets (gt, GTTITLE, title)

	switch (axis) {
	case 1:
	    call ic_pstr (ic, "xlabel", "Column")
	    call xt_21imavg (im, axis, 1, IM_LEN(im, 1), i, j, x, data, imlen)
	case 2:
	    call ic_pstr (ic, "xlabel", "Line")
	    call xt_21imavg (im, axis, i, j, 1, IM_LEN(im, 2), x, data, imlen)
	}
	call mfree (x, TY_REAL)

	stat = OK
	return (stat)
end
