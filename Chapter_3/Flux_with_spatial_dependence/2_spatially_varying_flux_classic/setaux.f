c     ============================================
      subroutine setaux(mbc,mx,xlower,dx,maux,aux)
c     ============================================
c     
c     # set auxiliary arrays 
 
c
      implicit none

      integer, intent(in) :: mbc, mx, maux
      double precision, intent(in) :: xlower, dx
      double precision, intent(out) :: aux
      dimension aux(maux, 1-mbc:mx+mbc)

 

      integer i
      double precision xcell
      do i=1-mbc,0
         aux(1,i) = 0.d0
      enddo
      do i=1,mx+mbc
         xcell = xlower + (i-0.5d0)*dx
         aux(1,i) = 2.d0*sqrt(xcell)
      enddo

      return
      end
