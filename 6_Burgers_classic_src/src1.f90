
! =========================================================
subroutine src1(meqn,mbc,mx,xlower,dx,q,maux,aux,t,dt)
! =========================================================
    implicit none
  ! Input parameters
    integer, intent(in)      :: meqn,mbc,mx,maux
    double precision, intent(in) :: xlower,dx,t,dt

    !local
    integer :: i, method


    ! Output
    double precision, intent(inout)  :: q(meqn,1-mbc:mx+mbc)
    double precision,  intent(inout) :: aux(maux,1-mbc:mx+mbc)

    double precision :: mu, xlim, a
    common /comsrc/ mu, xlim, a


	method = 1
    select case(order)
		case(1)
			do i=1,mx
				q(1,i) = q(1,i)/(1.d0+mu*dt)
			end do
		case(2)
			do i=1,mx
				q(1,i) = q(1,i)*(1.d0-mu*dt/2.d0)/(1.d0+mu*dt/2.d0)
			end do
	end select


    return
end

