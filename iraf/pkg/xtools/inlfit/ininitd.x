.help ininit
INLFIT memory allocation procedures. All the calls to malloc() and realloc()
are grouped in this file. Acces to the INLFIT structure is restricted to
the in_get() and in_put() procedures, except for buffer allocation and
initialization.
.nf

User entry points:

    in_initd (in, func, dfunc, param, dparam, nparams, plist, nfparams)

Low level entry point:

    in_bfinitd (in, npts, nvars)
.fi
.endhelp

include	<pkg/inlfit.h>
include "inlfitdef.h"


# IN_INIT -- Initialize INLFIT parameter structure.

procedure in_initd (in, func, dfunc, param, dparam, nparams, plist, nfparams)

pointer	in			# INLFIT pointer
pointer	func			# fitting function address
pointer	dfunc			# derivative function address
double	param[nparams]		# parameter values
double	dparam[nparams]		# initial guess at uncertenties in parameters
size_t	nparams			# number of parameters
long	plist[nparams]		# list of active parameters
size_t	nfparams		# number of fitting paramters

size_t	sz_val
long	l_val
include <nullptr.inc>

begin
#	# Debug.
#	call eprintf (
#	    "in_init: in=%d, func=%d, dfunc=%d, npars=%d, nfpars=%d\n")
#	    call pargi (in)
#	    call pargi (func)
#	    call pargi (dfunc)
#	    call pargi (nparams)
#	    call pargi (nfparams)

	# Allocate the structure memory.
	sz_val = LEN_INLSTRUCT
	call malloc (in, sz_val, TY_STRUCT)

	# Allocate memory for parameter values, changes, and list.
	sz_val = nparams
	call malloc (IN_PARAM  (in), sz_val, TY_DOUBLE)
	call malloc (IN_DPARAM (in), sz_val, TY_DOUBLE)
	call malloc (IN_PLIST  (in), sz_val, TY_LONG)

	# Allocate space for strings. All strings are limited
	# to SZ_LINE or SZ_FNAME.
	sz_val = SZ_LINE
	call malloc (IN_LABELS(in), sz_val, TY_CHAR)
	call malloc (IN_UNITS(in), sz_val, TY_CHAR)
	call malloc (IN_FLABELS(in), sz_val, TY_CHAR)
	call malloc (IN_FUNITS(in), sz_val, TY_CHAR)
	call malloc (IN_PLABELS(in), sz_val, TY_CHAR)
	call malloc (IN_PUNITS(in), sz_val, TY_CHAR)
	call malloc (IN_VLABELS(in), sz_val, TY_CHAR)
	call malloc (IN_VUNITS(in), sz_val, TY_CHAR)
	call malloc (IN_USERLABELS(in), sz_val, TY_CHAR)
	call malloc (IN_USERUNITS(in), sz_val, TY_CHAR)
	sz_val = SZ_FNAME
	call malloc (IN_HELP(in), sz_val, TY_CHAR)
	call malloc (IN_PROMPT(in), sz_val, TY_CHAR)

	# Allocate space for floating point and graph substructures.
	sz_val = LEN_INLFLOAT
	call malloc (IN_SFLOAT (in), sz_val, TY_DOUBLE)
	sz_val = INLNGKEYS * LEN_INLGRAPH
	call malloc (IN_SGAXES (in), sz_val, TY_INT)

	# Enter procedure parameters into the structure.
	call in_putp (in, INLFUNCTION, func)
	call in_putp (in, INLDERIVATIVE, dfunc)
	l_val = nparams
	call in_putl (in, INLNPARAMS, l_val)
	l_val = nfparams
	call in_putl (in, INLNFPARAMS, l_val)
	sz_val = nparams
	call amovd  (param, Memd[IN_PARAM(in)], sz_val)
	call amovd  (dparam, Memd[IN_DPARAM(in)], sz_val)
	call amovl   (plist, Meml[IN_PLIST(in)], sz_val)

	# Set defaults, just in case.
	call in_putd (in, INLTOLERANCE, double (0.01))
	call in_puti  (in, INLMAXITER, 3)
	call in_puti  (in, INLNREJECT, 0)
	call in_putd (in, INLLOW, double (3.0))
	call in_putd (in, INLHIGH, double (3.0))
	call in_putd (in, INLGROW, double (0.0))

	# Initialize the character strings.
	call in_pstr (in, INLLABELS, KEY_TYPES)
	call in_pstr (in, INLUNITS, "")
	call in_pstr (in, INLFLABELS, "")
	call in_pstr (in, INLFUNITS, "")
	call in_pstr (in, INLPLABELS, "")
	call in_pstr (in, INLPUNITS, "")
	call in_pstr (in, INLVLABELS, "")
	call in_pstr (in, INLVUNITS, "")
	call in_pstr (in, INLUSERLABELS, "")
	call in_pstr (in, INLUSERUNITS,  "")
	call in_pstr (in, INLHELP, IN_DEFHELP)
	call in_pstr (in, INLPROMPT, IN_DEFPROMPT)

	# Initialize user defined functions.
	call in_putp (in, INLUAXES,  NULLPTR)
	call in_puti (in, INLUCOLON, INDEFI)
	call in_puti (in, INLUFIT,   INDEFI)

	# Initialize graph key, and axes.
	call in_puti (in, INLGKEY, 2)
	call in_pkey (in, 1, INLXAXIS, KEY_FUNCTION, INDEFI)
	call in_pkey (in, 1, INLYAXIS, KEY_FIT, INDEFI)
	call in_pkey (in, 2, INLXAXIS, KEY_FUNCTION, INDEFI)
	call in_pkey (in, 2, INLYAXIS, KEY_RESIDUALS, INDEFI)
	call in_pkey (in, 3, INLXAXIS, KEY_FUNCTION, INDEFI)
	call in_pkey (in, 3, INLYAXIS, KEY_RATIO, INDEFI)
	call in_pkey (in, 4, INLXAXIS, KEY_VARIABLE, 1)
	call in_pkey (in, 4, INLYAXIS, KEY_RESIDUALS, INDEFI)
	call in_pkey (in, 5, INLXAXIS, KEY_FUNCTION, INDEFI)
	call in_pkey (in, 5, INLYAXIS, KEY_RESIDUALS, INDEFI)

	# Initialize flags and counters.
	call in_puti (in, INLOVERPLOT, NO)
	call in_puti (in, INLPLOTFIT, NO)
	call in_puti (in, INLNREJPTS, 0)
	call in_puti (in, INLNVARS, 0)
	call in_puti (in, INLNPTS, 0)

	# Initialize pointers.
	call in_putp (in, INLREJPTS, NULLPTR)
	call in_putp (in, INLXMIN,   NULLPTR)
	call in_putp (in, INLXMAX,   NULLPTR)
end


# IN_BFINIT -- Initialize the rejected point counter, number of variables,
# rejected point list, and the buffers containing the minimum and maximum
# variable values. The rejected point list and limit value buffers are
# reallocated, if necessary.

procedure in_bfinitd (in, npts, nvars)

pointer	in			# INLFIT descriptor
size_t	npts			# number of points
int	nvars			# number of variables

size_t	sz_val
int	in_geti()
long	in_getl()

begin
#	# Debug.
#	call eprintf ("in_bfinit: in=%d, npts=%d, nvars=%d\n")
#	    call pargi (in)
#	    call pargi (npts)
#	    call pargi (nvars)

	# Clear rejected point counter, and initialize number of variables.
	call in_puti (in, INLNREJPTS, 0)

	# Reallocate space for rejected point list and initialize it.
	if (in_getl (in, INLNPTS) != npts) {
	    call in_putl (in, INLNPTS, npts)
	    call realloc (IN_REJPTS (in), npts, TY_INT)
	}
	call amovki  (NO, Memi[IN_REJPTS(in)], npts)

	# Reallocate space for minimum and maximum variable values.
	# Initialization is made afterwards.
	if (in_geti (in, INLNVARS) != nvars) {
	    call in_puti (in, INLNVARS, nvars)
	    sz_val = nvars
	    call realloc (IN_XMIN (in), sz_val, TY_DOUBLE)
	    call realloc (IN_XMAX (in), sz_val, TY_DOUBLE)
	}
end
