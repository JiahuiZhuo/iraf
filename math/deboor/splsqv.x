# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.


include	"bspln.h"
define	ILLEGAL_ORDER	2	#error returns
define	NO_DEG_FREEDOM	3


.help splsqv 2 "IRAF Math Library"

Adapted from L2APPR, * A Practical Guide To Splines *  by C. DeBoor.
Eliminated data entry via the common /data/ (D.Tody, 4-july-82).  Calls
subprograms  BSPLVB, BCHFAC, BCHSLV.

SPLSQV constructs the (weighted discrete) l2-approximation by splines of
order K with knot sequence  T[1], ..., t[nt+k]  to given data points
(TAU[i], GTAU[i]), i=1,...,ntau.  The b-spline coefficients BCOEF of the
approximating spline are determined from the normal equations using
Cholesky'smethod.

SPLSQV (tau, gtau, weight, ntau, t, nt, k, work, diag, bcoef, ier)


INPUT -----

ntau		Number of data points
tau[ntau]	x-value of the data points.
gtau[ntau]	y-value of the data points.
weight[ntau]	The corresponding weights.
t[nt]		The knot sequence
nt		The dimension of the space of splines of order k with knots t.
k		The order of the b-spline to be fitted.


WORK ARRAYS -----

work[k,nt]	A work array of size (at least) K*NT. its first K rows are used
		for the K lower diagonals of the gramian matrix C.
diag[nt]	A work array of length NT used in BCHFAC.


OUTPUT -----

bcoef[nt]	The b-spline coefficients of the l2-approximation.
ier		Error code: zero if ok, else small integer error code.


METHOD -----

The b-spline coefficients of the l2-appr. are determined as the solution
of the normal equations

	sum ((B[i],B[j]) * BCOEF[j] : j=1:nt) = (B[i],G), 	i = 1 to nt.

where, B[i] denotes the i-th b-spline, G denotes the function to be
approximated, and the INNER PRODUCT of two functions F and G is given by

	(F,G)  :=  sum (F(TAU[i]) * G(TAU[i]) * WEIGHT[i] : i=1:ntau).

The relevant function values of the b-splines  B[i], i=1:nt, are supplied
by the subprogram BSPLVB.  The coeff. matrix C, with

	C(i,j) :=  (B[i], B[j]), i,j=1:n,

of the normal equations is symmetric and (2*k-1)-banded, therefore can be
specified by giving its k bands at or below the diagonal. for i=1,...,n,
we store

	(B[i],B[j])  =  B[i,j]  in  WORK[i-j+1,j], j=i,...,min0(i+k-1,nt)

and the right side

	(B[i], G)  in  BCOEF[i].

since b-spline values are most efficiently generated by finding simultaneously
the value of EVERY nonzero b-spline at one point, the entries of C (i.e., of
WORK), are generated by computing, for each ll, all the terms involving
TAU(ll) simultaneously and adding them to all relevant entries.
.endhelp _______________________________________________________________


procedure splsqv (tau, gtau, weight, ntau, t, nt, k, work, diag, bcoef, ier)

real	tau[ntau], gtau[ntau], weight[ntau]
real	t[nt], work[k,nt], diag[nt], bcoef[nt]
int	ntau, nt, k, ier
int	i, j, jj, left, leftmk, ll, mm
real	biatx[KMAX], dw

begin
	ier = 0
	if (k < 1 || k > KMAX) {
	    ier = ILLEGAL_ORDER
	    return
	}
	if (nt <= k || nt >= ntau+k) {
	    ier = NO_DEG_FREEDOM
	    return
	}

	do j = 1, nt {
	    bcoef[j] = 0.
	    do i = 1, k
		work[i,j] = 0.
	}

	left = k
	leftmk = 0

	do ll = 1, ntau {
	    while (left != nt) {
		if (tau[ll] < t[left+1])
		    break
		left = left + 1
		leftmk = leftmk + 1
	    }

	    call bsplvb (t, k, 1, tau[ll], left, biatx)

#   BIATX[mm] contains the value of B[left-k+mm] at TAU[ll].
#   hence, with DW := BIATX[mm] * WEIGHT[ll], the number DW * GTAU[ll]
#   is a summand in the inner product
#      (B[left-k+mm],G)  which goes into  BCOEF[left-k+mm]
#   and the number BIATX[jj] * dw is a summand in the inner product
#      (B[left-k+jj],  B[left-k+mm]),  into  WORK[jj-mm+1,left-k+mm]
#   since (left-k+jj) - (left-k+mm) + 1 = jj - mm + 1.

	    do mm = 1, k {
		dw = biatx[mm] * weight[ll]
		j = leftmk + mm
		bcoef[j] = dw * gtau[ll] + bcoef[j]
		i = 1

		do jj = mm, k {
		    work[i,j] = biatx[jj] * dw + work[i,j]
		    i = i + 1
		}
	    }
	}

#  construct cholesky factorization for C in WORK,  then use it to solve
#  the normal equations
#       c * x = bcoef
#  for X, and store X in BCOEF.

	call bchfac (work, k, nt, diag)
	call bchslv (work, k, nt, bcoef)
	return
end