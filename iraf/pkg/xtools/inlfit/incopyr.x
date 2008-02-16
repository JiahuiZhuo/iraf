include	<pkg/inlfit.h>
include	"inlfitdef.h"

# IN_COPY -- Copy INLFIT parameter structure, into another. The destination
# structure is allocated if the pointer is NULL.

procedure in_copyr (insrc, indst)

pointer	insrc			# source INLFIT pointer
pointer	indst			# destination INLFIT pointer

size_t	sz_val
int	in_geti()
real	in_getr()
pointer	in_getp()

begin
#	# Debug.
#	call eprintf (
#	    "in_copy: insrc=%d, indst=%d\n")
#	    call pargi (insrc)
#	    call pargi (indst)

	# Allocate destination.
	if (indst == NULL) {

	    # Allocate structure memory.
	    sz_val = LEN_INLSTRUCT
	    call malloc (indst, sz_val, TY_STRUCT)

	    # Allocate memory for parameter values, changes, and list.
	    sz_val = in_geti (insrc, INLNPARAMS)
	    call malloc (IN_PARAM  (indst), sz_val,
			 TY_REAL)
	    sz_val = in_geti (insrc, INLNPARAMS)
	    call malloc (IN_DPARAM (indst), sz_val,
			 TY_REAL)
	    sz_val = in_geti (insrc, INLNPARAMS)
	    call malloc (IN_PLIST  (indst), sz_val,
			 TY_INT)

	    # Allocate space for strings. All strings are limited
	    # to SZ_LINE or SZ_FNAME.
	    sz_val = SZ_LINE
	    call malloc (IN_LABELS     (indst), sz_val,  TY_CHAR)
	    call malloc (IN_UNITS      (indst), sz_val,  TY_CHAR)
	    call malloc (IN_FLABELS    (indst), sz_val,  TY_CHAR)
	    call malloc (IN_FUNITS     (indst), sz_val,  TY_CHAR)
	    call malloc (IN_PLABELS    (indst), sz_val,  TY_CHAR)
	    call malloc (IN_PUNITS     (indst), sz_val,  TY_CHAR)
	    call malloc (IN_VLABELS    (indst), sz_val,  TY_CHAR)
	    call malloc (IN_VUNITS     (indst), sz_val,  TY_CHAR)
	    call malloc (IN_USERLABELS (indst), sz_val,  TY_CHAR)
	    call malloc (IN_USERUNITS  (indst), sz_val,  TY_CHAR)
	    sz_val = SZ_FNAME
	    call malloc (IN_HELP       (indst), sz_val, TY_CHAR)
	    call malloc (IN_PROMPT     (indst), sz_val, TY_CHAR)

	    # Allocate space for floating point and graph substructures.
	    sz_val = LEN_INLFLOAT
	    call malloc (IN_SFLOAT (indst), sz_val, TY_REAL)
	    sz_val = INLNGKEYS * LEN_INLGRAPH
	    call malloc (IN_SGAXES (indst), sz_val, TY_INT)
	}

	# Copy integer parameters.
	call in_puti (indst, INLFUNCTION,   in_geti (insrc, INLFUNCTION))
	call in_puti (indst, INLDERIVATIVE, in_geti (insrc, INLDERIVATIVE))
	call in_puti (indst, INLNPARAMS,    in_geti (insrc, INLNPARAMS))
	call in_puti (indst, INLNFPARAMS,   in_geti (insrc, INLNFPARAMS))

	# Copy parameter values, changes, and list.
	call amovr  (Memr[in_getp (insrc, INLPARAM)],
		      Memr[in_getp (indst, INLPARAM)],
		      in_geti (insrc, INLNPARAMS))
	call amovr  (Memr[in_getp (insrc, INLDPARAM)],
		      Memr[in_getp (indst, INLDPARAM)],
		      in_geti (insrc, INLNPARAMS))
	call amovi   (Memi[in_getp (insrc, INLPLIST)],
		      Memi[in_getp (indst, INLPLIST)],
		      in_geti (insrc, INLNPARAMS))

	# Copy defaults.
	call in_putr (indst, INLTOLERANCE, in_getr (insrc, INLTOLERANCE))
	call in_puti  (indst, INLMAXITER,   in_geti  (insrc, INLMAXITER))
	call in_puti  (indst, INLNREJECT,   in_geti  (insrc, INLNREJECT))
	call in_putr (indst, INLLOW,       in_getr (insrc, INLLOW))
	call in_putr (indst, INLHIGH,      in_getr (insrc, INLHIGH))
	call in_putr (indst, INLGROW,      in_getr (insrc, INLGROW))

	# Copy character strings.
	call in_pstr (indst, INLLABELS,     Memc[IN_LABELS     (insrc)])
	call in_pstr (indst, INLUNITS,      Memc[IN_UNITS      (insrc)])
	call in_pstr (indst, INLFLABELS,    Memc[IN_FLABELS    (insrc)])
	call in_pstr (indst, INLFUNITS,     Memc[IN_FUNITS     (insrc)])
	call in_pstr (indst, INLPLABELS,    Memc[IN_PLABELS    (insrc)])
	call in_pstr (indst, INLPUNITS,     Memc[IN_PUNITS     (insrc)])
	call in_pstr (indst, INLVLABELS,    Memc[IN_VLABELS    (insrc)])
	call in_pstr (indst, INLVUNITS,     Memc[IN_VUNITS     (insrc)])
	call in_pstr (indst, INLUSERLABELS, Memc[IN_USERLABELS (insrc)])
	call in_pstr (indst, INLUSERUNITS,  Memc[IN_USERUNITS  (insrc)])
	call in_pstr (indst, INLHELP,       Memc[IN_HELP       (insrc)])
	call in_pstr (indst, INLPROMPT,     Memc[IN_PROMPT     (insrc)])

	# Copy user defined functions.
	call in_puti (indst, INLUAXES,  in_geti (insrc, INLUAXES))
	call in_puti (indst, INLUCOLON, in_geti (insrc, INLUCOLON))
	call in_puti (indst, INLUFIT,   in_geti (insrc, INLUFIT))

	# Copy graph key, and axes.
	call in_puti (indst, INLGKEY, in_geti (insrc, INLGKEY))
	call amovi (IN_SGAXES (insrc), IN_SGAXES (indst),
	    INLNGKEYS * LEN_INLGRAPH)

	# Copy flags and counters.
	call in_puti (indst, INLOVERPLOT, in_geti (insrc, INLOVERPLOT))
	call in_puti (indst, INLPLOTFIT,  in_geti (insrc, INLPLOTFIT))
	call in_puti (indst, INLNREJPTS,  in_geti (insrc, INLNREJPTS))

	# Initialize number of points and variables.
	call in_puti (indst, INLNVARS, 0)
	call in_puti (indst, INLNPTS,  0)

	# Reallocate rejected point list and limit values.
	call in_bfinit (indst, in_geti (insrc, INLNPTS),
	    in_geti (insrc, INLNVARS))

	# Copy rejected point list and limit values.
	call amovi  (Memp[in_getp (insrc, INLREJPTS)],
	    Memp[in_getp (indst, INLREJPTS)], in_geti (indst, INLNPTS))
	call amovr (Memr[in_getp (insrc, INLXMIN)],
	    Memr[in_getp (indst, INLXMIN)], in_geti (indst, INLNVARS))
	call amovr (Memr[in_getp (insrc, INLXMAX)],
	    Memr[in_getp (indst, INLXMAX)], in_geti (indst, INLNVARS))
end
