# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include <imhdr.h>
include <math.h>
include <math/gsurfit.h>
include "geotran.h"

# T_GEOTRAN -- Procedure to geometrically transform a set of images.

procedure t_geotran ()

char	imtlist1[SZ_LINE]		# input image list
char	imtlist2[SZ_LINE]		# ouptut image list
char	database[SZ_FNAME]		# name of data base file
char	transform[SZ_FNAME]		# name of transformation
char	record[SZ_FNAME]		# record name
int	ncols, nlines			# output picture size
real	xmin, xmax, ymin, ymax		# minimum and maximum ref values
real	xscale, yscale			# output picture scale
real	xin, yin			# input picture origin
real	xshift, yshift			# x and y shifts
real	xout, yout			# output picture origin
real	xmag, ymag			# input picture scale
real	xrotation, yrotation		# rotation angle
int	nxblock, nyblock		# block size of image to be used

char	image1[SZ_FNAME]			# input image
char	image2[SZ_FNAME]			# output image
char	imtemp[SZ_FNAME]			# temporary file

char	str[SZ_LINE]
int	list1, list2, tflist
pointer	sp, geo, sx1, sy1, sx2, sy2, in, out, mw
real	oltv[2], nltv[2], oltm[2,2], nltm[2,2]

bool	clgetb(), envgetb()
int	imtopen(), imtlen(), clgeti(), imtgetim(), clgwrd(), btoi()
int	fntopnb(), fntgfnb(), fntlenb()
pointer	immap(), mw_openim()
real	clgetr()

begin
	# Set up  the geotran structure.
	call smark (sp)
	call salloc (geo, LEN_GEOSTRUCT, TY_STRUCT)

	# Get the input and output lists and database file.
	call clgstr ("input", imtlist1, SZ_FNAME)
	call clgstr ("output", imtlist2, SZ_FNAME)
	call clgstr ("database", database, SZ_FNAME)
	if (database[1] != EOS) {
	    call clgstr ("transform", transform, SZ_FNAME)
	    tflist = fntopnb (transform, NO)
	    GT_GEOMODE(geo) = clgwrd ("geometry", str, SZ_LINE, 
	        ",junk,linear,distortion,geometric,")
	} else {
	    tflist = NULL
	    GT_GEOMODE(geo) = GT_NONE
	}

	# Get the output picture format parameters.
	xmin = clgetr ("xmin")
	xmax = clgetr ("xmax")
	ymin = clgetr ("ymin")
	ymax = clgetr ("ymax")
	xscale = clgetr ("xscale")
	yscale = clgetr ("yscale")
	ncols= clgeti ("ncols")
	nlines = clgeti ("nlines")

	# Get the geometric transformation parameters.
	xin = clgetr ("xin")
	yin = clgetr ("yin")
	xshift = clgetr ("xshift")
	yshift = clgetr ("yshift")
	xout = clgetr ("xout")
	yout = clgetr ("yout")
	xmag = clgetr ("xmag")
	ymag = clgetr ("ymag")
	xrotation = clgetr ("xrotation")
	yrotation = clgetr ("yrotation")

	# Get the interpolation parameters.
	GT_INTERPOLANT(geo) = clgwrd ("interpolant", str, SZ_LINE, 
	    ",nearest,linear,poly3,poly5,spline3,")
	GT_BOUNDARY(geo) = clgwrd ("boundary", str, SZ_LINE,
	    ",constant,nearest,reflect,wrap,")
	GT_CONSTANT(geo) = clgetr ("constant")
	GT_XSAMPLE(geo) = clgetr ("xsample")
	GT_YSAMPLE(geo) = clgetr ("ysample")
	GT_FLUXCONSERVE(geo) = btoi (clgetb("fluxconserve"))
	nxblock = clgeti ("nxblock")
	nyblock = clgeti ("nyblock")

	# Open the lists of images and check the scale lengths.
	list1 = imtopen (imtlist1)
	list2 = imtopen (imtlist2)
	if (imtlen (list1) != imtlen (list2)) {
	    call imtclose (list1)
	    call imtclose (list2)
	    if (tflist != NULL)
	        call fntclsb (tflist)
	    call error (0, "Input and output lists not the same length.")
	}

	# Check the transform list.
	if (tflist != NULL) {
	    if (fntlenb (tflist) > 1 && fntlenb (tflist) != imtlen (list1)) {
	        call imtclose (list1)
	        call imtclose (list2)
	        call fntclsb (tflist)
	        call error (0, "Transform and input lists not the same length.")
	    }
	}

	# Loop over the images.
	while (imtgetim (list1, image1, SZ_FNAME) != EOF && imtgetim (list2,
	    image2, SZ_FNAME) != EOF) {

	    # Open the images.
	    call xt_mkimtemp (image1, image2, imtemp, SZ_FNAME)
	    in = immap (image1, READ_ONLY, 0)
	    out = immap (image2, NEW_COPY, in)

	    # Set the parameters.
	    call geoset (geo, xmin, xmax, ymin, ymax, xscale, yscale, ncols,
		nlines, xin, yin, xshift, yshift, xout, yout, xmag, ymag,
		xrotation, yrotation)

	    # Get the coordinate surfaces.
	    if (GT_GEOMODE(geo) == GT_NONE)
		call geoformat (in, out, geo, sx1, sy1, sx2, sy2)
	    else { 
		if (fntgfnb (tflist, record, SZ_FNAME) != EOF)
		    ;
	        call geodformat (in, out, geo, database, record, sx1, sy1,
		    sx2, sy2)
	    }

	    # Transform the image.
	    if (IM_LEN(out,1) <= nxblock && IM_LEN(out,2) <= nyblock) {
	        if (GT_XSAMPLE(geo) > 1.0 || GT_YSAMPLE(geo) > 1.0)
		    call geosimtran (in, out, geo, sx1, sy1, sx2, sy2,
		        int (IM_LEN(out,1)), int (IM_LEN(out,2)))
	        else
	            call geoimtran (in, out, geo, sx1, sy1, sx2, sy2,
		        int (IM_LEN(out,1)), int (IM_LEN(out,2)))
	    } else {
	        if (GT_XSAMPLE(geo) > 1.0 || GT_YSAMPLE(geo) > 1.0)
		    call geostran (in, out, geo, sx1, sy1, sx2, sy2, nxblock,
		        nyblock)
	        else
	            call geotran (in, out, geo, sx1, sy1, sx2, sy2, nxblock,
		        nyblock)
	    }

	    # Update the linear part of the wcs.
	    if (!envgetb ("nomwcs")) {
		mw = mw_openim (in)
		call geowcs (geo, sx1, sy1, oltm, oltv)
		call mw_invertr (oltm, nltm, 2)
		call mw_vmulr (nltm, oltv, nltv, 2)
		call anegr (nltv, nltv, 2)
		call mw_sltermr (mw, nltm, nltv, 2)
		call mw_saveim (mw, out)
		call mw_close (mw)
	    }

	    # Free the surfaces.
	    call gsfree (sx1)
	    call gsfree (sy1)
	    call gsfree (sx2)
	    call gsfree (sy2)

	    # Close the images.
	    call imunmap (in)
	    call imunmap (out)

	    call xt_delimtemp (image2, imtemp)
	}

	# Clean up.
	call sfree (sp)
	if (tflist != NULL)
	    call fntclsb (tflist)
	call imtclose (list1)
	call imtclose (list2)
end


# GEOSET -- Set picture dependent task parameters.

procedure geoset (geo, xmin, xmax, ymin, ymax, xscale, yscale, ncols, nlines,
    xin, yin, xshift, yshift, xout, yout, xmag, ymag, xrotation, yrotation)

pointer	geo			# pointer to geotran structure
real	xmin, xmax		# minimum and maximum reference values
real	ymin, ymax		# minimum and maximum reference values
real	xscale, yscale		# output picture scale
int	ncols, nlines		# output picture size
real	xin, yin		# input picture pixel coordinates
real	xshift, yshift		# shift of origin
real	xout, yout		# corresponding output picture coords
real	xmag, ymag		# input picture scale
real	xrotation, yrotation	# scale angle

begin
	# output picture format parameters
	GT_XMIN(geo) = xmin
	GT_XMAX(geo) = xmax
	GT_YMIN(geo) = ymin
	GT_YMAX(geo) = ymax
	GT_XSCALE(geo) = xscale
	GT_YSCALE(geo) = yscale
	GT_NCOLS(geo) = ncols
	GT_NLINES(geo) = nlines

	# transformation parameters
	GT_XIN(geo) = xin
	GT_YIN(geo) = yin
	GT_XSHIFT(geo) = xshift
	GT_YSHIFT(geo) = yshift
	GT_XOUT(geo) = xout
	GT_YOUT(geo) = yout
	GT_XMAG(geo) = xmag
	GT_YMAG(geo) = ymag
	GT_XROTATION(geo) = xrotation
	GT_YROTATION(geo) = yrotation
end


# GEOFORMAT -- Format the output picture when there is no database file.

procedure geoformat (in, out, geo, sx1, sy1, sx2, sy2)

pointer	in		# pointer to the input image
pointer	out		# pointer to the ouput image
pointer	geo		# pointer to the geotran structure
pointer sx1, sy1	# pointer to linear surfaces
pointer	sx2, sy2	# pointer to distortion surfaces

real	xmax, ymax

begin
	# Get the rotation and scale transformation parameters.
	if (IS_INDEFR(GT_XMAG(geo)))
	    GT_XMAG(geo) = 1.
	if (IS_INDEFR(GT_YMAG(geo)))
	    GT_YMAG(geo) = 1.
	if (IS_INDEFR(GT_XROTATION(geo)))
	    GT_XROTATION(geo) =  DEGTORAD(0.)
	else
	    GT_XROTATION(geo) =  DEGTORAD(GT_XROTATION(geo))
	if (IS_INDEFR(GT_YROTATION(geo)))
	    GT_YROTATION(geo) =  DEGTORAD(0.)
	else
	    GT_YROTATION(geo) =  DEGTORAD(GT_YROTATION(geo))

	# Compute the maximum extent of the image.
	xmax = abs (cos (GT_XROTATION(geo)) * IM_LEN(in, 1) / GT_XMAG(geo)) +
	    abs (sin (GT_XROTATION(geo)) * IM_LEN(in,2) / GT_YMAG(geo))
	ymax = abs (sin (GT_YROTATION(geo)) * IM_LEN(in, 1) / GT_XMAG(geo)) +
	    abs (cos (GT_YROTATION(geo)) * IM_LEN(in,2) / GT_YMAG(geo))

	# Set up the x reference coordinate limits.
	if (IS_INDEF(GT_XMIN(geo)))
	    GT_XMIN(geo) = 1.
	else
	    GT_XMIN(geo) = max (1., min (GT_XMIN(geo), xmax))
	if (IS_INDEF(GT_XMAX(geo)))
	    GT_XMAX(geo) = IM_LEN(in,1)
	else if (GT_XMAX(geo) <= 0.0)
	    GT_XMAX(geo) = xmax
	else
	    GT_XMAX(geo) = min (xmax, max (1., GT_XMAX(geo)))

	# Set up y reference coordinate limits.
	if (IS_INDEF(GT_YMIN(geo)))
	    GT_YMIN(geo) = 1.
	else
	    GT_YMIN(geo) = max (1., min (GT_YMIN(geo), ymax))
	if (IS_INDEF(GT_YMAX(geo)))
	    GT_YMAX(geo) = IM_LEN(in, 2)
	else if (GT_YMAX(geo) <= 0.0)
	    GT_YMAX(geo) = ymax
	else
	    GT_YMAX(geo) = min (ymax, max (1., GT_YMAX(geo)))

	# Set the number of columns and rows.
	if (IS_INDEFI(GT_NCOLS(geo)))
	    GT_NCOLS(geo) = IM_LEN(in, 1)
	if (IS_INDEFI(GT_NLINES(geo)))
	    GT_NLINES(geo) = IM_LEN(in, 2)

	# Set scale, overide number of columns and rows if necessary. 
	if (IS_INDEFR(GT_XSCALE(geo)))
	    GT_XSCALE(geo) = (GT_XMAX(geo) - GT_XMIN(geo)) / (GT_NCOLS(geo) - 1)
	else
	    GT_NCOLS(geo) = (GT_XMAX(geo) - GT_XMIN(geo)) / GT_XSCALE(geo) + 1
	if (IS_INDEFR(GT_YSCALE(geo)))
	    GT_YSCALE(geo) = (GT_YMAX(geo) - GT_YMIN(geo)) /
	        (GT_NLINES(geo) - 1)
	else
	    GT_NLINES(geo) = (GT_YMAX(geo) - GT_YMIN(geo)) / GT_YSCALE(geo) + 1
	IM_LEN(out, 1) = GT_NCOLS(geo)
	IM_LEN(out, 2) = GT_NLINES(geo)

	# Set up the surfaces, distortion surfaces are NULL.
	call gsinit (sx1, GS_POLYNOMIAL, 2, 2, NO, GT_XMIN(geo), GT_XMAX(geo),
	    GT_YMIN(geo), GT_YMAX(geo))
	call gsinit (sy1, GS_POLYNOMIAL, 2, 2, NO, GT_XMIN(geo), GT_XMAX(geo),
	    GT_YMIN(geo), GT_YMAX(geo))
	sx2 = NULL
	sy2 = NULL

	# Adjust rotation, x and y scale, scale angle, and flip.
	call geogscoeff (sx1, sy1, GT_XMAG(geo), GT_YMAG(geo),
	    GT_XROTATION(geo), GT_YROTATION(geo))

	# Adjust the shift.
	call geoshift (in, out, geo, sx1, sy1)
end


# GEODFORMAT -- Get the coordinate transformation from a database file.

procedure geodformat (in, out, geo, database, transform, sx1, sy1, sx2, sy2)

pointer	in, out			# pointers to input and output images
pointer	geo			# pointer to geotran structure
char	database[ARB]		# name of database file
char	transform[ARB]		# name of transform
pointer	sx1, sy1		# pointer to linear part of surface fit
pointer	sx2, sy2		# pointer to higher order surface

int	i, dt, rec, ncoeff, junk
pointer	xcoeff, ycoeff, newsx1, newsy1
int	dtmap(), dtlocate(), dtgeti(), dtscan()
errchk	gsrestore

begin
	# Map the database and locate the transformation record.
	dt = dtmap (database, READ_ONLY)
	rec = dtlocate (dt, transform)

	# Get the linear part of the fit.
	ncoeff = dtgeti (dt, rec, "surface1")
	call malloc (xcoeff, ncoeff, TY_REAL)
	call malloc (ycoeff, ncoeff, TY_REAL)
	do i = 1, ncoeff {
	    junk = dtscan (dt)
	    call gargr (Memr[xcoeff+i-1])
	    call gargr (Memr[ycoeff+i-1])
	}
	call gsrestore (sx1, Memr[xcoeff])
	call gsrestore (sy1, Memr[ycoeff])

	# Set the output image format parameters.
	call geodout (in, out, geo, sx1, sy1)

	# Adjust the linear part of the fit.
	call gscopy (sx1, newsx1)
	call gscopy (sy1, newsy1)
	if (GT_GEOMODE(geo) == GT_DISTORT)
	    call geogscoeff (newsx1, newsy1, 1.0, 1.0, 0.0, 0.0)
	else if (! IS_INDEFR(GT_XMAG(geo)) || ! IS_INDEFR(GT_YMAG(geo)) ||
	    ! IS_INDEFR(GT_XROTATION(geo)) || ! IS_INDEFR(GT_YROTATION(geo)))
	    call geodcoeff (geo, dt, rec, newsx1, newsy1)
	call geodshift (in, out, dt, rec, geo, newsx1, newsy1)

	# Get the higher order part of the fit.
	ncoeff = dtgeti (dt, rec, "surface2")
	if (ncoeff > 0 && (GT_GEOMODE(geo) == GT_GEOMETRIC || GT_GEOMODE(geo) ==
	    GT_DISTORT)) {

	    # Get the distortion coefficients.
	    call realloc (xcoeff, ncoeff, TY_REAL)
	    call realloc (ycoeff, ncoeff, TY_REAL)
	    do i = 1, ncoeff {
	        junk = dtscan(dt)
	        call gargr (Memr[xcoeff+i-1])
	        call gargr (Memr[ycoeff+i-1])
	    }
	    iferr {
	        call gsrestore (sx2, Memr[xcoeff])
	    } then {
		call mfree (sx2, TY_STRUCT)
		sx2 = NULL
	    }
	    iferr {
	        call gsrestore (sy2, Memr[ycoeff])
	    } then {
		call mfree (sy2, TY_STRUCT)
		sy2 = NULL
	    }

	} else {

	    sx2 = NULL
	    sy2 = NULL
	}

	# Redefine the surfaces.
	call gsfree (sx1)
	call gscopy (newsx1, sx1)
	call gsfree (newsx1)
	call gsfree (sy1)
	call gscopy (newsy1, sy1)
	call gsfree (newsy1)

	# Cleanup.
	call mfree (xcoeff, TY_REAL)
	call mfree (ycoeff, TY_REAL)
	call dtunmap (dt)
end


# GEODBOUT --  Set the output image format.

procedure geodout (in, out, geo, sx1, sy1)

pointer	in, out		# pointers to input and output image
pointer	geo		# pointer to geotran sturcture
pointer	sx1, sy1	# pointer to linear image

real	gsgetr ()

begin
	# Set the reference coordinate limits.
	if (IS_INDEFR(GT_XMIN(geo)))
	    GT_XMIN(geo) = gsgetr (sx1, GSXMIN)
	if (IS_INDEFR(GT_XMAX(geo)))
	    GT_XMAX(geo) = gsgetr (sx1, GSXMAX)
	if (IS_INDEFR(GT_YMIN(geo)))
	    GT_YMIN(geo) = gsgetr (sy1, GSYMIN)
	if (IS_INDEFR(GT_YMAX(geo)))
	    GT_YMAX(geo) = gsgetr (sy1, GSYMAX)

	# Set the number of lines and columns.
	if (IS_INDEFI(GT_NCOLS(geo)))
	    GT_NCOLS(geo) = IM_LEN(in, 1)
	if (IS_INDEFI(GT_NLINES(geo)))
	    GT_NLINES(geo) = IM_LEN(in, 2)

	# Set scale, overiding the number of columns and rows if necessary. 
	if (IS_INDEFR(GT_XSCALE(geo)))
	    GT_XSCALE(geo) = (GT_XMAX(geo) - GT_XMIN(geo)) / (GT_NCOLS(geo) - 1)
	else
	    GT_NCOLS(geo) = (GT_XMAX(geo) - GT_XMIN(geo)) / GT_XSCALE(geo) + 1
	if (IS_INDEFR(GT_YSCALE(geo)))
	    GT_YSCALE(geo) = (GT_YMAX(geo) - GT_YMIN(geo)) /
	        (GT_NLINES(geo) - 1)
	else
	    GT_NLINES(geo) = (GT_YMAX(geo) - GT_YMIN(geo)) / GT_YSCALE(geo) + 1

	# Set the output image size.
	IM_LEN(out,1) = GT_NCOLS(geo)
	IM_LEN(out,2) = GT_NLINES(geo)
end


# GEODSHIFT -- Adjust the shifts.

procedure geodshift (in, out, dt, rec, geo, sx1, sy1)

pointer	in, out		# pointer to input and output images
pointer	dt		# pointer to database
int	rec		# pointer to database record
pointer	geo		# pointer to geotran structure
pointer	sx1, sy1	# pointers to linear surfaces

real	gseval()

begin
	# Define the output origin.
	if (IS_INDEFR(GT_XOUT(geo)))
	    GT_XOUT(geo) = (GT_XMAX(geo) + GT_XMIN(geo)) / 2.0
	if (IS_INDEFR(GT_YOUT(geo)))
	    GT_YOUT(geo) = (GT_YMAX(geo) + GT_YMIN(geo)) / 2.0

	# Define the input image origin.
	if (IS_INDEFR(GT_XIN(geo)))
	    GT_XIN(geo) = gseval (sx1, GT_XOUT(geo), GT_YOUT(geo))
	if (IS_INDEFR(GT_YIN(geo)))
	    GT_YIN(geo) = gseval (sy1, GT_XOUT(geo), GT_YOUT(geo))

	# Define the shifts.
	if (IS_INDEFR(GT_XSHIFT(geo)))
	    GT_XSHIFT(geo) = GT_XIN(geo) - gseval (sx1, GT_XOUT(geo),
	        GT_YOUT(geo))
	if (IS_INDEFR(GT_YSHIFT(geo)))
	    GT_YSHIFT(geo) = GT_YIN(geo) - gseval (sy1, GT_XOUT(geo),
	        GT_YOUT(geo))
	
	# Correct the coefficients.
	call geogsshift (sx1, sy1, GT_XSHIFT(geo), GT_YSHIFT(geo))
end


# GEOSHIFT -- Compute the shift.

procedure geoshift (in, out, geo, sx1, sy1)

pointer	in, out		# pointer to input and output images
pointer	geo		# pointer to geotran structure
pointer	sx1, sy1	# pointers to linear surfaces

real	gseval()

begin
	# Determine the output origin.
	if (IS_INDEFR(GT_XOUT(geo)))
	    GT_XOUT(geo) =  (GT_XMAX(geo) + GT_XMIN(geo)) / 2.0
	if (IS_INDEFR(GT_YOUT(geo)))
	    GT_YOUT(geo) =  (GT_YMAX(geo) + GT_YMIN(geo)) / 2.0

	# Determine the final xshift.
	if (IS_INDEFR(GT_XSHIFT(geo))) {
	    if (IS_INDEFR(GT_XIN(geo)))
	        GT_XIN(geo) = (real (IM_LEN (in, 1)) + 1.) / 2.
	    GT_XSHIFT(geo) = GT_XIN(geo) - gseval (sx1, GT_XOUT(geo),
	        GT_YOUT(geo))
	} else {
	    GT_XIN(geo) = (GT_XOUT(geo) - GT_XMIN(geo)) / GT_XSCALE(geo) -
		GT_XSHIFT(geo) + 1.0
	    GT_XSHIFT(geo) = GT_XIN(geo) - gseval (sx1, GT_XOUT(geo),
	        GT_YOUT(geo))
	}

	# Determine the final y shift.
	if (IS_INDEFR(GT_YSHIFT(geo))) {
	    if (IS_INDEFR(GT_YIN(geo)))
	        GT_YIN(geo) = (real (IM_LEN (in, 2)) + 1.) / 2.
	    GT_YSHIFT(geo) = GT_YIN(geo) - gseval (sy1, GT_XOUT(geo),
	        GT_YOUT(geo))
	} else {
	    GT_YIN(geo) = (GT_YOUT(geo) - GT_YMIN(geo)) / GT_YSCALE(geo) -
		GT_YSHIFT(geo) + 1.0
	    GT_YSHIFT(geo) = GT_YIN(geo) - gseval (sy1, GT_XOUT(geo),
	        GT_YOUT(geo))
	}

	# Alter coefficients.
	call geogsshift (sx1, sy1, GT_XSHIFT(geo), GT_YSHIFT(geo))
end


# GEOGSSHIFT -- Shift the coefficients.

procedure geogsshift (sx1, sy1, xshift, yshift)

pointer	sx1, sy1	# pointers to linear surface
real	xshift, yshift	# shifts

int	ncoeff
pointer	sp, xcoeff, ycoeff
int	gsgeti()

begin
	call smark (sp)

	# Allocate working space.
	ncoeff = max (gsgeti (sx1, GSNSAVE), gsgeti (sy1, GSNSAVE))
	call salloc (xcoeff, ncoeff, TY_REAL)
	call salloc (ycoeff, ncoeff, TY_REAL)

	# Get coefficients.
	call gssave (sx1, Memr[xcoeff])
	call gssave (sy1, Memr[ycoeff])

	# Shift.
	Memr[xcoeff+GS_SAVECOEFF] = Memr[xcoeff+GS_SAVECOEFF] + xshift
	Memr[ycoeff+GS_SAVECOEFF] = Memr[ycoeff+GS_SAVECOEFF] + yshift

	# Free original fit.
	call gsfree (sx1)
	call gsfree (sy1)

	# Restore the fit.
	call gsrestore (sx1, Memr[xcoeff])
	call gsrestore (sy1, Memr[ycoeff])

	call sfree (sp)
end


# GEODCOEFF -- Transform the coefficients.

procedure geodcoeff (geo, dt, rec, sx1, sy1)

pointer	geo		# pointer to geotran structure
pointer	dt		# pointer to database record
int	rec		# database record
pointer	sx1, sy1	# pointers to the linear surface

real	dtgetr()
errchk	dtgetr()

begin
	# Get the transformation parameters.
	if (IS_INDEFR(GT_XMAG(geo))) {
	    iferr (GT_XMAG(geo) = dtgetr (dt, rec, "xmag"))
	        GT_XMAG(geo) = dtgetr (dt, rec, "xscale")
	}
	if (IS_INDEFR(GT_YMAG(geo))) {
	    iferr (GT_YMAG(geo) = dtgetr (dt, rec, "ymag"))
	        GT_YMAG(geo) = dtgetr (dt, rec, "yscale")
	}
	if (IS_INDEFR(GT_XROTATION(geo)))
	    GT_XROTATION(geo) =  DEGTORAD(dtgetr (dt, rec, "xrotation"))
	else
	    GT_XROTATION(geo) = DEGTORAD(GT_XROTATION(geo))
	if (IS_INDEFR(GT_YROTATION(geo)))
	    GT_YROTATION(geo) =  DEGTORAD(dtgetr (dt, rec, "yrotation"))
	else
	    GT_YROTATION(geo) = DEGTORAD(GT_YROTATION(geo))

	call geogscoeff (sx1, sy1, GT_XMAG(geo), GT_YMAG(geo),
	    GT_XROTATION(geo), GT_YROTATION(geo))
end


# GEOGSCOEFF -- Procedure to alter the coefficients of the surface

procedure geogscoeff (sx1, sy1, xscale, yscale, xrotation, yrotation)

pointer	sx1, sy1		# pointer to the linear surface
real	xscale, yscale		# x and y scales
real	xrotation,yrotation	# rotation angle radians

int	ncoeff
pointer	sp, xcoeff, ycoeff
real	cosx, sinx, cosy, siny, xrange, yrange

int	gsgeti()
real	gsgetr()

begin
	call smark (sp)
	ncoeff = max (gsgeti (sx1, GSNSAVE), gsgeti (sy1, GSNSAVE))
	call salloc (xcoeff, ncoeff, TY_REAL)
	call salloc (ycoeff, ncoeff, TY_REAL)

	# Extract the original coefficients.
	call gssave (sx1, Memr[xcoeff])
	call gssave (sy1, Memr[ycoeff])

	# Define the scaling parameters.
	cosx = cos (xrotation)
	sinx = sin (xrotation)
	cosy = cos (yrotation)
	siny = sin (yrotation)

	# Calculate the coefficients.
	Memr[xcoeff+GS_SAVECOEFF+1] =  xscale * cosx
	Memr[xcoeff+GS_SAVECOEFF+2] =  yscale * sinx
	Memr[ycoeff+GS_SAVECOEFF+1] = -xscale * siny
	Memr[ycoeff+GS_SAVECOEFF+2] =  yscale * cosy

	# Normalize coefficients for non polynomial functions.
	xrange = gsgetr (sx1, GSXMAX) - gsgetr (sx1, GSXMIN)
	yrange = gsgetr (sy1, GSYMAX) - gsgetr (sy1, GSYMIN)
	if (gsgeti (sx1, GSTYPE) != GS_POLYNOMIAL) {
	    Memr[xcoeff+GS_SAVECOEFF+1] = Memr[xcoeff+GS_SAVECOEFF+1] *
	        xrange / 2.
	    Memr[xcoeff+GS_SAVECOEFF+2] = Memr[xcoeff+GS_SAVECOEFF+2] *
	        yrange / 2.
	}
	if (gsgeti (sy1, GSTYPE) != GS_POLYNOMIAL) {
	    Memr[ycoeff+GS_SAVECOEFF+1] = Memr[ycoeff+GS_SAVECOEFF+1] *
	        xrange / 2.
	    Memr[ycoeff+GS_SAVECOEFF+2] = Memr[ycoeff+GS_SAVECOEFF+2] *
	        yrange / 2.
	}

	# Free original fit.
	call gsfree (sx1)
	call gsfree (sy1)

	# Restore fit.
	call gsrestore (sx1, Memr[xcoeff])
	call gsrestore (sy1, Memr[ycoeff])

	call sfree (sp)
end


# GEOWCS -- Compute the ltm and ltv vectors required by the wcs interface.

procedure geowcs (geo, sx1, sy1, ltm, ltv)

pointer	geo		# pointer to the geotran structure
pointer	sx1		# pointer to the linear x coordinate surface
pointer	sy1		# pointer to the linear y coordinate surface
real	ltm[2,2]	# rotation matrix
real	ltv[2]		# shift vector

int	ncoeff
pointer	sp, xcoeff, ycoeff
real	xrange, yrange
int	gsgeti()
real	gsgetr()

begin
	# Allocate space for the coefficients.
	call smark (sp)
	ncoeff = max (gsgeti (sx1, GSNSAVE), gsgeti (sy1, GSNSAVE))
	call salloc (xcoeff, ncoeff, TY_REAL)
	call salloc (ycoeff, ncoeff, TY_REAL)

	# Fetch the coeeficients.
	call gssave (sx1, Memr[xcoeff])
	call gssave (sy1, Memr[ycoeff])

	# Denormalize the coefficients for non-polynomial functions.
	xrange = gsgetr (sx1, GSXMAX) - gsgetr (sx1, GSXMIN)
	yrange = gsgetr (sy1, GSYMAX) - gsgetr (sy1, GSYMIN)
	if (gsgeti (sx1, GSTYPE) != GS_POLYNOMIAL) {
	    Memr[xcoeff+GS_SAVECOEFF+1] = Memr[xcoeff+GS_SAVECOEFF+1] * 2. /
	        xrange
	    Memr[xcoeff+GS_SAVECOEFF+2] = Memr[xcoeff+GS_SAVECOEFF+2] * 2. /
	        yrange
	}
	if (gsgeti (sy1, GSTYPE) != GS_POLYNOMIAL) {
	    Memr[ycoeff+GS_SAVECOEFF+1] = Memr[ycoeff+GS_SAVECOEFF+1] * 2. /
	        xrange
	    Memr[ycoeff+GS_SAVECOEFF+2] = Memr[ycoeff+GS_SAVECOEFF+2] * 2. /
	        yrange
	}

	# Set the shift vector.
	ltv[1] = Memr[xcoeff+GS_SAVECOEFF]
	ltv[2] = Memr[ycoeff+GS_SAVECOEFF]

	# Set the rotation vector.
	ltm[1,1] = Memr[xcoeff+GS_SAVECOEFF+1]
	ltm[2,1] = Memr[xcoeff+GS_SAVECOEFF+2]
	ltm[1,2] = Memr[ycoeff+GS_SAVECOEFF+1]
	ltm[2,2] = Memr[ycoeff+GS_SAVECOEFF+2]

	# Correct for reference units that are not in pixels.
	ltv[1] = ltv[1] + ltm[1,1] * GT_XMIN(geo) + ltm[2,1] * GT_YMIN(geo) -
	    ltm[1,1] * GT_XSCALE(geo) - ltm[2,1] * GT_YSCALE(geo)
	ltv[2] = ltv[2] + ltm[1,2] * GT_XMIN(geo) + ltm[2,2] * GT_YMIN(geo) -
	    ltm[1,2] * GT_XSCALE(geo) - ltm[2,2] * GT_YSCALE(geo)
	ltm[1,1] = ltm[1,1] * GT_XSCALE(geo)
	ltm[2,1] = ltm[2,1] * GT_YSCALE(geo)
	ltm[1,2] = ltm[1,2] * GT_XSCALE(geo)
	ltm[2,2] = ltm[2,2] * GT_YSCALE(geo)

	call sfree (sp)
end