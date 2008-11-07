include <pkg/inlfit.h>

# ING_VARIABLES -- Write the variable numbers, names and minimum and maximum
# values to a file.

procedure ing_variablesr (in, file, nvars)

pointer	in			# pointer to the inlfit structure
char	file[ARB]		# output file name
int	nvars			# number of variables

size_t	sz_val
int	i, fd
long	l_val
pointer	sp, labels, pvnames, name, minptr, maxptr
int	open()
long	inlstrwrd()
pointer	in_getp()

begin
	if (file[1] == EOS)
	    return
	fd = open (file, APPEND, TEXT_FILE)

	call smark (sp)
	sz_val = SZ_LINE
	call salloc (labels, sz_val, TY_CHAR)
	call salloc (pvnames, sz_val, TY_CHAR)
	call salloc (name, sz_val, TY_CHAR)
	call in_gstr (in, INLVLABELS, Memc[labels], SZ_LINE)
	call strcpy (Memc[labels], Memc[pvnames], SZ_LINE)

	# Print the title string.
	call fprintf (fd, "\n%-10.10s  %-10.10s  %14.14s  %14.14s\n")
	    call pargstr ("number")
	    call pargstr ("variable")
	    call pargstr ("minimum")
	    call pargstr ("maximum")

	# Print the variables.
	minptr = in_getp (in, INLXMIN)
	maxptr = in_getp (in, INLXMAX)
	do i = 1, nvars {
	    l_val = i
	    if (inlstrwrd (l_val, Memc[name], SZ_LINE, Memc[pvnames]) == 0) {
		call sprintf (Memc[name], SZ_LINE, "var %d")
		    call pargi (i)
	    }
	    call fprintf (fd, "%-10.2d  %-10.10s  ")
		call pargi (i)
		call pargstr (Memc[name])
	    call fprintf (fd, "%14.7f  %14.7f\n")
		call pargr (Memr[minptr+i-1])
		call pargr (Memr[maxptr+i-1])
	}
	call fprintf (fd, "\n")

	call close (fd)
	call sfree (sp)
end
