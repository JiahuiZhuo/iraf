.help ininit
INLFIT memory allocation procedures. All the calls to malloc() and realloc()
are grouped in this file. Acces to the INLFIT structure is restricted to
the in_get() and in_put() procedures, except for buffer allocation and
initialization.
.nf

User entry points:

    in_initr (in, func, dfunc, param, dparam, nparams, plist, nfparams)

Low level entry point:

    in_bfinitr (in, npts, nvars)
.fi
.endhelp

include	<pkg/inlfit.h>
include "inlfitdef.h"


# IN_INIT -- Initialize INLFIT parameter structure.

procedure in_initr (in, func, dfunc, param, dparam, nparams, plist, nfparams)

pointer	in			# INLFIT pointer
int	func			# fitting function address
int	dfunc			# derivative function address
real	param[nparams]		# parameter values
real	dparam[nparams]		# initial guess at uncertenties in parameters
int	nparams			# number of parameters
int	plist[nparams]		# list of active parameters
size_t	sz_val
int	nfparams		# number of fitting paramters

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
	call malloc (IN_PARAM  (in), sz_val, TY_REAL)
	call malloc (IN_DPARAM (in), sz_val, TY_REAL)
	call malloc (IN_PLIST  (in), sz_val, TY_INT)

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
	call malloc (IN_SFLOAT (in), sz_val, TY_REAL)
	sz_val = INLNGKEYS * LEN_INLGRAPH
	call malloc (IN_SGAXES (in), sz_val, TY_INT)

	# Enter procedure parameters into the structure.
	call in_puti (in, INLFUNCTION, func)
	call in_puti (in, INLDERIVATIVE, dfunc)
	call in_puti (in, INLNPARAMS, nparams)
	call in_puti (in, INLNFPARAMS, nfparams)
	call amovr  (param, Memr[IN_PARAM(in)], nparams)
	call amovr  (dparam, Memr[IN_DPARAM(in)], nparams)
	call amovi   (plist, Memi[IN_PLIST(in)], nparams)

	# Set defaults, just in case.
	call in_putr (in, INLTOLERANCE, real (0.01))
	call in_puti  (in, INLMAXITER, 3)
	call in_puti  (in, INLNREJECT, 0)
	call in_putr (in, INLLOW, real (3.0))
	call in_putr (in, INLHIGH, real (3.0))
	call in_putr (in, INLGROW, real (0.0))

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
	call in_puti (in, INLUAXES,  INDEFI)
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
	call in_putp (in, INLREJPTS, NULL)
	call in_putp (in, INLXMIN,   NULL)
	call in_putp (in, INLXMAX,   NULL)
end


# IN_BFINIT -- Initialize the rejected point counter, number of variables,
# rejected point list, and the buffers containing the minimum and maximum
# variable values. The rejected point list and limit value buffers are
# reallocated, if necessary.

procedure in_bfinitr (in, npts, nvars)

pointer	in			# INLFIT descriptor
int	npts			# number of points
int	nvars			# number of variables

int	in_geti()

begin
#	# Debug.
#	call eprintf ("in_bfinit: in=%d, npts=%d, nvars=%d\n")
#	    call pargi (in)
#	    call pargi (npts)
#	    call pargi (nvars)

	# Clear rejected point counter, and initialize number of variables.
	call in_puti (in, INLNREJPTS, 0)

	# Reallocate space for rejected point list and initialize it.
	if (in_geti (in, INLNPTS) != npts) {
	    call in_puti (in, INLNPTS, npts)
	    call realloc (IN_REJPTS (in), npts, TY_INT)
	}
	call amovki  (NO, Memi[IN_REJPTS(in)], npts)

	# Reallocate space for minimum and maximum variable values.
	# Initialization is made afterwards.
	if (in_geti (in, INLNVARS) != nvars) {
	    call in_puti (in, INLNVARS, nvars)
	    call realloc (IN_XMIN (in), nvars, TY_REAL)
	    call realloc (IN_XMAX (in), nvars, TY_REAL)
	}
end
