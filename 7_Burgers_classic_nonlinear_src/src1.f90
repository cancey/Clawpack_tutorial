
! =========================================================
subroutine src1(meqn,mbc,mx,xlower,dx,q,maux,aux,t,dt)
! =========================================================
    use exchange
    implicit none
  ! Input parameters
    integer, intent(in)      :: meqn,mbc,mx,maux
    double precision, intent(in) :: xlower,dx,t,dt

    !local
    integer :: i 


    ! Output
    double precision, intent(inout)  :: q(meqn,1-mbc:mx+mbc)
    double precision,  intent(inout) :: aux(maux,1-mbc:mx+mbc)

    double precision :: mu, xlim, a
    integer :: method
    common /comsrc/ mu, xlim, a, method
    double precision :: x, f, fx, tol
    integer, parameter :: n = 1
    integer :: info


	 
    select case(method)
		case(1)
			do i=1,mx
				q(1,i) = q(1,i)/(1.d0+mu*dt*q(1,i))
			end do
		case(2)
			do i=1,mx
				q(1,i) = (-1.d0+sqrt(1.d0+4.d0*dt*q(1,i)*mu))/2.d0/dt/mu
			end do
		case(3)
			do i=1,mx
				call export_params(params,(/q(1,i), mu, dt/))
				x = q(1,i)
				tol = 1.d-8
				call fsolve ( fsource, n, x, fx, tol, info )
				q(1,i) = x
			end do
	end select


    return
end

