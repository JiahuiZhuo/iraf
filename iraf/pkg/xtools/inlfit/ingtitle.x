include <pkg/gtools.h>

# ING_TITLE -- Write out the time stamp and the title of the current fit.

procedure ing_title (in, file, gt)

pointer	in		# pointer to the inlfit structure (not used yet)
char	file[ARB]	# arbitrary file name
pointer	gt		# pointer to the gtools structure

size_t	sz_val
int	fd, sfd
long	l_val
pointer	sp, str
int	open(), stropen(), fscan()
long	clktime()

begin
	if (file[1] == EOS)
	    return
	fd = open (file, APPEND, TEXT_FILE)

	call smark (sp)
	sz_val = SZ_LINE
	call salloc (str, sz_val, TY_CHAR)

	# Put time stamp in.
	l_val = 0
	call cnvtime (clktime(l_val), Memc[str], SZ_LINE)
	call fprintf (fd, "\n#%s\n")
	    call pargstr (Memc[str])

	# Print plot title.
	call gt_gets (gt, GTTITLE, Memc[str], SZ_LINE)
	sfd = stropen (Memc[str], SZ_LINE, READ_ONLY)
	while (fscan (sfd) != EOF) {
	    call gargstr (Memc[str], SZ_LINE)
	    call fprintf (fd, "#%s\n")
	        call pargstr (Memc[str])
	} 
	call fprintf (fd, "\n")
	call strclose (sfd)

	# Print fit units.
	#call gt_gets (gt, GTYUNITS, Memc[str], SZ_LINE)
	#if (Memc[str] != EOS) {
	    #call fprintf (fd, "fit_units    %s\n")
	        #call pargstr (Memc[str])
	#}

	call sfree (sp)
	call close (fd)
end
