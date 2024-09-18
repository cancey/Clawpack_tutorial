
! =========================================================
subroutine qinit(meqn,mbc,mx,xlower,dx,q,maux,aux)
! =========================================================
!
!     # Set initial conditions for q.
!
!
    implicit double precision (a-h,o-z)
    dimension q(meqn,1-mbc:mx+mbc)
    dimension aux(maux,1-mbc:mx+mbc)
    common /comsrc/ mu, xlim, a

    do i=1,mx
        xcell = xlower + (i-0.5d0)*dx
        q(1,i) = 0.d0
        if ((xcell >= 0.d0) .and. (xcell <=xlim)) then
            q(1,i) = a*xcell
        end if
    end do
 
     
    return
end
