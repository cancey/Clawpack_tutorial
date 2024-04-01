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
c        # unit box
         q(1,i) = 1.d0
         if (xcell .lt. -0.5d0) q(1,i) = 0.d0
         if (xcell .gt. 0.5d0) q(1,i) = 0.d0


  150    continue
c
      return
      end
