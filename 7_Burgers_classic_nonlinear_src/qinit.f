c
c
c =========================================================
       subroutine qinit(meqn,mbc,mx,xlower,dx,q,maux,aux)
c =========================================================
c
c     # Set initial conditions for q.
c
c
      implicit double precision (a-h,o-z)
      dimension q(meqn,1-mbc:mx+mbc)
      dimension aux(maux,1-mbc:mx+mbc)
      common /comsrc/ dcoef
c
c
      do 150 i=1,mx
	 xcell = xlower + (i-0.5d0)*dx
c        # Heaviside
c         q(1,i) = 2.d0
c         if (xcell .lt. 0.d0) q(1,i) = 0.d0
         ul = 0.d0
	 ur = 2.d0

         q(1,i) = (ur+ul)/2-dabs((ul-ur))/2.d0*tanh(xcell*(ul-ur)/  
     &                  4.d0/dcoef) 

  150    continue
c
      return
      end
