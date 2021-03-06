include	"../lib/mctable.h"


# MCT_RESTORE - Restore table from a text file.

procedure mct_restore (fname, table)

char	fname[ARB]		# file name
pointer	table			# table descriptor

char	cval
short	sval
int	fd, magic, type, row, col, nprows, npcols
int	maxcol, maxrow, lastcol, ival
long	lval
pointer	pval
real	rval
double	dval
complex	xval

int	open(), fscan(), nscan()
errchk	mct_alloc()
errchk	mct_putc(), mct_puts(), mct_puti(), mct_putl()
errchk	mct_putr(), mct_putd(), mct_putx(), mct_putp()

begin
	# Open file.
	iferr (fd = open (fname, READ_ONLY, TEXT_FILE))
	    call error (0, "mct_restore: Cannot open file")

	# Read and check magic number.
	if (fscan (fd) != EOF) {
	    call gargi (magic)
	    if (magic != MAGIC)
	        call error (0, "mct_restore: Bad magic number")
	} else
	    call error (0, "mct_restore: Unexpected end of file (magic)")

	# Read type.
	if (fscan (fd) != EOF)
	    call gargi (type)
	else
	    call error (0, "mct_restore: Unexpected end of file (type)")

	# Read max number of rows.
	if (fscan (fd) != EOF)
	    call gargi (maxrow)
	else
	    call error (0, "mct_restore: Unexpected end of file (maxrow)")

	# Read max number of columns.
	if (fscan (fd) != EOF)
	    call gargi (maxcol)
	else
	    call error (0, "mct_restore: Unexpected end of file (maxcol)")

	# Discard row increment.
	if (fscan (fd) != EOF)
	    call gargi (ival)
	else
	    call error (0, "mct_restore: Unexpected end of file (incrows)")

	# Read number of rows entered.
	if (fscan (fd) != EOF)
	    call gargi (nprows)
	else
	    call error (0, "mct_restore: Unexpected end of file (nprows)")

	# Read number of columns entered.
	if (fscan (fd) != EOF)
	    call gargi (npcols)
	else
	    call error (0, "mct_restore: Unexpected end of file (npcols)")

	# Read number of rows gotten.
	if (fscan (fd) != EOF)
	    call gargi (ival)
	else
	    call error (0, "mct_restore: Unexpected end of file (ngrows)")

	# Read number of columns gotten
	if (fscan (fd) != EOF)
	    call gargi (ival)
	else
	    call error (0, "mct_restore: Unexpected end of file (ngcols)")

	# Discard data pointer.
	if (fscan (fd) != EOF)
	    call gargi (ival)
	else
	    call error (0, "mct_restore: Unexpected end of file (pointer)")

	# Allocate table.
	call mct_alloc (table, maxrow, maxcol, type)

	# Loop over rows.
	lastcol = maxcol
	do row = 1, nprows {

	    # In the last row the column loop should go only until the
	    # highest column.
	    if (row == nprows)
		lastcol = npcols

	    # Start scanning next line.
	    if (fscan (fd) == EOF)
		call error (0, "mct_restore: Unexpected end of file (row)")

	    # Loop over columns.
	    for (col = 1; col <= lastcol; col = col + 1) {

		# Read data.
		switch (MCT_TYPE (table)) {

		case TY_CHAR:
		    call gargc (cval)
		    call mct_putc (table, row, col, cval)

		case TY_SHORT:
		    call gargs (sval)
		    call mct_puts (table, row, col, sval)

		case TY_INT:
		    call gargi (ival)
		    call mct_puti (table, row, col, ival)

		case TY_LONG:
		    call gargl (lval)
		    call mct_putl (table, row, col, lval)

		case TY_REAL:
		    call gargr (rval)
		    call mct_putr (table, row, col, rval)

		case TY_DOUBLE:
		    call gargd (dval)
		    call mct_putd (table, row, col, dval)

		case TY_COMPLEX:
		    call gargx (xval)
		    call mct_putx (table, row, col, xval)

		case TY_POINTER:
		    call gargi (pval)
		    call mct_putp (table, row, col, pval)

		default:
		    call error (0, "mct_save: Unknown data type")
		}

		# Check column read.
		if (nscan () != col)
		    call error (0, "mct_restore: Unexpcted end of file (col)")
	    }
	}

	# Close file.
	call close (fd)
end
