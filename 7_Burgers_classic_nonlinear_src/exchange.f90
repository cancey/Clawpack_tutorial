module exchange
implicit none
save
real(kind=8)   :: params(3)
contains

 
	
 
subroutine export_params(p,b)
	real(kind=8) :: p(3)
	real(kind=8) :: b(3)

	p(1:3) = b(1:3) 
	return

end subroutine export_params



subroutine fsource ( n, x, fx  )

!*****************************************************************************80
!
!! f2() evaluates a nonlinear system of 2 equations.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    19 August 2016
!
!  Author:
!
!    John Burkardt
!
!  Input:
!
!    integer N, the number of variables.
!
!    real ( kind = rk ) X(N), the variable values.
!
!  Output:
!
!    real ( kind = rk ) FX(N), the function values at X.
!
  implicit none
  integer n
  real (kind = 8) fx
  real (kind = 8) x
 

  real(kind=8) :: qn, mu, dt
  qn = params(1)
  mu = params(2)
  dt = params(3)

  fx  = x - qn + mu*dt*x**2
  return
end 

 

end module
