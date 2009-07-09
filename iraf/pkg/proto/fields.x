include <ctype.h>

include "fi.h"

# FIELDS -- Extract whitespace delimited fields from specified lines of 
# an input list.  A new list consisting of the extracted fields is output.
# Which lines and fields to extract is specified by the user.

procedure t_fields ()

pointer	sp, f_str, l_str, fin, list
bool	quit, name
long	lines[3, MAX_LINES], nlines
int	fields[MAX_FIELDS], nfields
int	ranges[3,MAX_RANGES], nranges

size_t	sz_val
bool	clgetb()
int	decode_ranges(), fi_decode_ranges(), clgfil()
pointer	clpopni()

begin
	# Allocate space on stack for char buffers
	call smark (sp)
	sz_val = SZ_LINE
	call salloc (f_str, sz_val, TY_CHAR)
	call salloc (l_str, sz_val, TY_CHAR)
	call salloc (fin, sz_val, TY_CHAR)

	# Open template of input files
	list = clpopni ("files")

	# Get boolean parameters
	quit = clgetb ("quit_if_missing")
	name = clgetb ("print_file_names")

	# Get the lines and fields to be extracted.  Decode ranges.
	call clgstr ("fields", Memc[f_str], SZ_LINE)
	call clgstr ("lines",  Memc[l_str], SZ_LINE)

	# Don't impose ordering on field specification
	if (fi_decode_ranges (Memc[f_str], ranges, MAX_RANGES, 1, 
	    MAX_FIELDS, nranges) == ERR) {
	    call error (0, "Error in field specification")
	} else
	    call fi_xpand (ranges, fields, nfields)

	# Lines range will be accessed in ascending order
	if (decode_ranges (Memc[l_str], lines, MAX_LINES, nlines) == ERR) 
	    call error (0, "Error in line specification")

	# While list of input files is not depleted, extract fields
	while (clgfil (list, Memc[fin], SZ_FNAME) != EOF) 
	    call fi_xtract (Memc[fin], lines, fields, nfields, quit, name)

	call clpcls (list)
	call sfree (sp)
end


# FI_XPAND -- expands the output from decode_ranges into an array.
# The output array contains the ordinal of each element in the range; 
# no ordering is imposed.

procedure fi_xpand (ranges, out, num)

int	ranges[3*MAX_RANGES] 		# Input ranges array
int     out[MAX_LINES]			# Output unordered list
int	num				# Number of entries in output list

int	ip, number
int	first, last, step

begin

	num = 0
	for (ip=1; ranges[ip] != NULL; ip=ip+3) {
	    first = ranges[ip]
	    last = ranges[ip+1]
	    step = ranges[ip+2]

	    if (first == last) {
		num = num + 1
		out[num] = first
		next
	    }

	    if (first > last)
		step = -1 * step
	    do number = first, last, step {
		num = num + 1
		out[num] = number
	    }
	}
end


# FI_DECODE_RANGES -- Parse a string containing a list of integer numbers or
# ranges, delimited by either spaces or commas.  Return as output a list
# of ranges defining a list of numbers, and the count of list numbers.
# Range limits must be positive nonnegative integers.  ERR is returned as
# the function value if a conversion error occurs.  The list of ranges is
# delimited by a single NULL.

int procedure fi_decode_ranges (range_string, ranges, max_ranges, minimum,
    maximum, nvalues)

char	range_string[SZ_LINE]	# Range string to be decoded
int	ranges[3, max_ranges]	# Range array
int	max_ranges		# Maximum number of ranges
int	minimum, maximum	# Minimum and maximum range values allowed
int	nvalues			# The number of values in the ranges

int	ip, nrange, a, b, first, last, step
int	ctoi()

begin
	ip = 1
	nrange = 1
	nvalues = 0

	while (nrange < max_ranges) {
	    # Default values
	    a = minimum
	    b = maximum
	    step = 1

	    # Skip delimiters
	    while (IS_WHITE(range_string[ip]) || range_string[ip] == ',')
		ip = ip + 1

	    # Get first limit.
	    # Must be a number, '-', 'x', or EOS.  If not return ERR.
	    if (range_string[ip] == EOS) {			# end of list
		if (nrange == 1) {
		    # Null string defaults
		    ranges[1, 1] = a
		    ranges[2, 1] = b
		    ranges[3, 1] = step
		    ranges[1, 2] = NULL
	    	    nvalues = (b - a) / step + 1
		    return (OK)
		} else {
		    ranges[1, nrange] = NULL
		    return (OK)
		}
	    } else if (range_string[ip] == '-')
		;
	    else if (range_string[ip] == 'x')
		;
	    else if (IS_DIGIT(range_string[ip])) {		# ,n..
		if (ctoi (range_string, ip, a) == 0)
		    return (ERR)
	    } else
		return (ERR)

	    # Skip delimiters
	    while (IS_WHITE(range_string[ip]) || range_string[ip] == ',')
		ip = ip + 1

	    # Get last limit
	    # Must be '-', or 'x' otherwise b = a.
	    if (range_string[ip] == 'x')
		;
	    else if (range_string[ip] == '-') {
		ip = ip + 1
	        while (IS_WHITE(range_string[ip]) || range_string[ip] == ',')
		    ip = ip + 1
		if (range_string[ip] == EOS)
		    ;
		else if (IS_DIGIT(range_string[ip])) {
		    if (ctoi (range_string, ip, b) == 0)
		        return (ERR)
		} else if (range_string[ip] == 'x')
		    ;
		else
		    return (ERR)
	    } else
		b = a

	    # Skip delimiters
	    while (IS_WHITE(range_string[ip]) || range_string[ip] == ',')
		ip = ip + 1

	    # Get step.
	    # Must be 'x' or assume default step.
	    if (range_string[ip] == 'x') {
		ip = ip + 1
	        while (IS_WHITE(range_string[ip]) || range_string[ip] == ',')
		    ip = ip + 1
		if (range_string[ip] == EOS)
		    ;
		else if (IS_DIGIT(range_string[ip])) {
		    if (ctoi (range_string, ip, step) == 0)
		        ;
		} else if (range_string[ip] == '-')
		    ;
		else
		    return (ERR)
	    }

	    # Output the range triple.
	    first = a
	    last = b
	    ranges[1, nrange] = first
	    ranges[2, nrange] = last
	    ranges[3, nrange] = step
	    nvalues = nvalues + iabs(last - first) / step + 1
	    nrange = nrange + 1
	}

	return (ERR)					# ran out of space
end


# FI_XTRACT -- filter out lines from which fields are to be extracted.
# Called once per input file, FI_XTRACT calls FI_PRECORD to process
# each extracted line.

procedure fi_xtract (in_fname, lines, fields, nfields, quit, name)

char	in_fname[SZ_FNAME]		# Input file name
long	lines[3,MAX_LINES]		# Ranges of lines to be extracted
int	fields[MAX_FIELDS]		# Fields to be extracted
int	nfields				# Number of fields to extract
bool	quit				# Quit if missing field (y/n)?
bool	name				# Print file name in each line (y/n)?

size_t	sz_val
pointer	sp, lbuf
int	in, st, i_val
long	in_line

bool	is_in_range()
int	open(), getlongline()
errchk	salloc, open, getlongline, fi_precord

begin
	# Allocate space for line buffer
	call smark (sp)
	sz_val = SZ_LINE
	call salloc (lbuf, sz_val, TY_CHAR)

	# Open input file
	in = open (in_fname, READ_ONLY, TEXT_FILE)

	# Position to specified input line
	in_line = 0
	repeat {
	    repeat {
		i_val = in_line
		st = getlongline (in, Memc[lbuf], SZ_LINE, i_val)
		in_line = i_val
	        if ( st == EOF) {
		    call close (in)
		    call sfree (sp)
	            return
		}
	    } until (is_in_range (lines, in_line))

	    call fi_precord (in_fname, Memc[lbuf], fields, nfields, quit, name)
	}	

	call close (in)
	call sfree (sp)
end
