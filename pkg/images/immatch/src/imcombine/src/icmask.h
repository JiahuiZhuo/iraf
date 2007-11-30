# ICMASK -- Data structure for IMCOMBINE mask interface.

define	ICM_LEN		5		# Structure length
define	ICM_TYPE	Memi[$1]	# Mask type
define	ICM_VALUE	Memi[$1+1]	# Mask value
define	ICM_BUFS	Memi[$1+2]	# Pointer to data line buffers
define	ICM_PMS		Memi[$1+3]	# Pointer to array of PMIO pointers
define	ICM_NAMES	Memi[$1+4]	# Pointer to array of mask names