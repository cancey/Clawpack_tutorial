      subroutine setprob
      implicit none
      character*12 fname
c      # common /cparam/ u
      double precision mu, xlim, a
      integer iunit, order
      common /comsrc/ mu, xlim, a
      common /comsrcorder/ order
c
c     # Set the velocity for scalar advection
c     # This value is passed to the Riemann solver rp1.f in a common block
c
c
c
      iunit = 7
      fname = 'setprob.data'
c     # open the unit with new routine from Clawpack 4.4 to skip over
c     # comment lines starting with #:
      call opendatafile(iunit, fname)
                
c      # read(7,*) u
      read(7,*) mu
      read(7,*) xlim
      read(7,*) a
      read(7,*) order

      return
      end

