# FIBER1 - Fiber example 1

file	out, obj, dat

out = s1
obj = mktemp ("art")
dat = mktemp ("art")

mk1dspec (obj, output="", rv=0., z=no, title="", ncols=512,
    wstart=4000., wend=8000., continuum=1000., slope=0., temperature=5700.,
    lines="", nlines=50, peak=-0.5, sigma=10., seed=1)

print (obj, " .1 gauss 3 0 10.1 .002", > dat)
print (obj, " .2 gauss 3 0 20.2 .002", >> dat)
print (obj, " .3 gauss 3 0 30.3 .002", >> dat)
print (obj, " .4 gauss 3 0 40.4 .002", >> dat)
print (obj, " .5 gauss 3 0 50.5 .002", >> dat)
print (obj, " .6 gauss 3 0 60.6 .002", >> dat)
print (obj, " .7 gauss 3 0 70.7 .002", >> dat)
print (obj, " .8 gauss 3 0 80.8 .002", >> dat)
print (obj, " .9 gauss 3 0 90.9 .002", >> dat)
mk2dspec (out, output="", model=dat, title="", ncols=100, nlines=512)

mknoise (out, output="", title="", ncols=512, nlines=512,
    background=0., gain=1., rdnoise=3., poisson=yes, seed=1, cosrays="",
    ncosrays=0, energy=30000., radius=0.5, ar=1., pa=0.)

imdelete (obj, verify=no)
delete (dat, verify=no)