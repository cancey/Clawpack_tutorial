subroutine backward_euler_residual ( dydt, n, to, yo, tm, ym, fm )

!*****************************************************************************80
!
!! backward_euler_residual() evaluates the backward Euler residual.
!
!  Discussion:
!
!    Let to and tm be two times, with yo and ym the associated ODE
!    solution values there.  If ym satisfies the backward Euler condition,
!    then
!
!      dydt(tm,ym) = ( ym - yo ) / ( tm - to )
!
!    This can be rewritten as
!
!      residual = ym - yo - ( tm - to ) * dydt(tm,ym)
!
!    Given the other information, a nonlinear equation solver can be used
!    to estimate the value ym that makes the residual zero.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    08 November 2023
!
!  Author:
!
!    John Burkardt
!
!  Input:
!
!    external dydt(): the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the vector size.
!
!    real ( kind = rk ) to, yo(n): the old time and solution.
!
!    real ( kind = rk ) tm, ym(n): the new time and tentative solution.
!
!  Output:
!
!    real ( kind = rk ) fm(n): the backward Euler residual.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) dydtm(n)
  external dydt
  real ( kind = rk ) fm(n)
  real ( kind = rk ) tm
  real ( kind = rk ) to
  real ( kind = rk ) ym(n)
  real ( kind = rk ) yo(n)

  call dydt ( tm, ym, dydtm )

  fm = ym - yo - ( tm - to ) * dydtm

  return
end
subroutine bdf2_residual ( dydt, n, t1, y1, t2, y2, t3, y3, fm )

!*****************************************************************************80
!
!! bdf2_residual() evaluates the backward difference order 2 residual.
!
!  Discussion:
!
!    Let t1, t2 and t3 be three times, with y1, y2 and y3 the associated ODE
!    solution values there.  Assume only the y3 value may be varied.
!
!    The BDF2 condition is:
!
!      w = ( t3 - t2 ) / ( t2 - t1 )
!      b = ( 1 + w )^2 / ( 1 + 2 w )
!      c = w^2 / ( 1 + 2 w )
!      d = ( 1 + w ) / ( 1 + 2 w )
!
!      y3 - b y2 + c y1 = ( t3 - t2 ) * dydt( t3, y3 )
!
!    but if (t3-t2) = (t2-t1), we have:
!
!      w = 1
!      b = 4/3
!      c = 1/3
!      d = 2/3
!      y3 - 4/3 y2 + 1/3 y1 = 2 dt * dydt( t3, y3 )
!
!    This can be rewritten as
!
!      residual = y3 - b y2 + c y1 - ( t3 - t2 ) * dydt(t3,y3)
!
!    This is the BDF2 residual to be evaluated.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    17 November 2023
!
!  Author:
!
!    John Burkardt
!
!  Input:
!
!    external dydt(): the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the vector size.
!
!    real ( kind = rk ) t1, y1(n), t2, y2(n), t3, y3(n): three sets of
!    data at a sequence of times.
!
!  Output:
!
!    real ( kind = rk ) fm(n): the residual.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) b
  real ( kind = rk ) c
  real ( kind = rk ) d
  real ( kind = rk ) dydt3(n)
  external dydt
  real ( kind = rk ) fm(n)
  real ( kind = rk ) t1
  real ( kind = rk ) t2
  real ( kind = rk ) t3
  real ( kind = rk ) w
  real ( kind = rk ) y1(n)
  real ( kind = rk ) y2(n)
  real ( kind = rk ) y3(n)

  w = ( t3 - t2 ) / ( t2 - t1 )
  b = ( 1.0D+00 + w )**2 / ( 1.0D+00 + 2.0D+00 * w )
  c = w**2 / ( 1.0D+00 + 2.0D+00 * w )
  d = ( 1.0D+00 + w ) / ( 1.0D+00 + 2.0D+00 * w )

  call dydt ( t3, y3, dydt3 )

  fm = y3 - b * y2 + c * y1 - d * ( t3 - t2 ) * dydt3

  return
end
subroutine dogleg ( n, r, lr, diag, qtb, delta, x )

!*****************************************************************************80
!
!! dogleg() finds the minimizing combination of Gauss-Newton and gradient steps.
!
!  Discussion:
!
!    Given an M by N matrix A, an N by N nonsingular diagonal
!    matrix D, an M-vector B, and a positive number DELTA, the
!    problem is to determine the convex combination X of the
!    Gauss-Newton and scaled gradient directions that minimizes
!    (A*X - B) in the least squares sense, subject to the
!    restriction that the euclidean norm of D*X be at most DELTA.
!
!    This function completes the solution of the problem
!    if it is provided with the necessary information from the
!    QR factorization of A.  That is, if A = Q*R, where Q has
!    orthogonal columns and R is an upper triangular matrix,
!    then DOGLEG expects the full upper triangle of R and
!    the first N components of Q'*B.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, integer N, the order of the matrix R.
!
!    Input, real ( kind = rk ) R(LR), the upper triangular matrix R stored
!    by rows.
!
!    Input, integer LR, the size of the R array, which must be 
!    no less than (N*(N+1))/2.
!
!    Input, real ( kind = rk ) DIAG(N), the diagonal elements of the matrix D.
!
!    Input, real ( kind = rk ) QTB(N), the first N elements of the vector Q'* B.
!
!    Input, real ( kind = rk ) DELTA, is a positive upper bound on the
!    euclidean norm of D*X(1:N).
!
!    Output, real ( kind = rk ) X(N), the desired convex combination of the
!    Gauss-Newton direction and the scaled gradient direction.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer lr
  integer n

  real ( kind = rk ) alpha
  real ( kind = rk ) bnorm
  real ( kind = rk ) delta
  real ( kind = rk ) diag(n)
  real ( kind = rk ) enorm
  real ( kind = rk ) epsmch
  real ( kind = rk ) gnorm
  integer i
  integer j
  integer jj
  integer k
  integer l
  real ( kind = rk ) qnorm
  real ( kind = rk ) qtb(n)
  real ( kind = rk ) r(lr)
  real ( kind = rk ) sgnorm
  real ( kind = rk ) sum2
  real ( kind = rk ) temp
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) x(n)

  epsmch = epsilon ( epsmch )
!
!  Calculate the Gauss-Newton direction.
!
  jj = ( n * ( n + 1 ) ) / 2 + 1

  do k = 1, n

     j = n - k + 1
     jj = jj - k
     l = jj + 1
     sum2 = 0.0D+00

     do i = j + 1, n
       sum2 = sum2 + r(l) * x(i)
       l = l + 1
     end do

     temp = r(jj)

     if ( temp == 0.0D+00 ) then

       l = j
       do i = 1, j
         temp = max ( temp, abs ( r(l)) )
         l = l + n - i
       end do

       if ( temp == 0.0D+00 ) then
         temp = epsmch
       else
         temp = epsmch * temp
       end if

     end if

     x(j) = ( qtb(j) - sum2 ) / temp

  end do
!
!  Test whether the Gauss-Newton direction is acceptable.
!
  wa1(1:n) = 0.0D+00
  wa2(1:n) = diag(1:n) * x(1:n)
  qnorm = enorm ( n, wa2 )

  if ( qnorm <= delta ) then
    return
  end if
!
!  The Gauss-Newton direction is not acceptable.
!  Calculate the scaled gradient direction.
!
  l = 1
  do j = 1, n
     temp = qtb(j)
     do i = j, n
       wa1(i) = wa1(i) + r(l) * temp
       l = l + 1
     end do
     wa1(j) = wa1(j) / diag(j)
  end do
!
!  Calculate the norm of the scaled gradient.
!  Test for the special case in which the scaled gradient is zero.
!
  gnorm = enorm ( n, wa1 )
  sgnorm = 0.0D+00
  alpha = delta / qnorm

  if ( gnorm /= 0.0D+00 ) then
!
!  Calculate the point along the scaled gradient which minimizes the quadratic.
!
    wa1(1:n) = ( wa1(1:n) / gnorm ) / diag(1:n)

    l = 1
    do j = 1, n
      sum2 = 0.0D+00
      do i = j, n
        sum2 = sum2 + r(l) * wa1(i)
        l = l + 1
      end do
      wa2(j) = sum2
    end do

    temp = enorm ( n, wa2 )
    sgnorm = ( gnorm / temp ) / temp
!
!  Test whether the scaled gradient direction is acceptable.
!
    alpha = 0.0D+00
!
!  The scaled gradient direction is not acceptable.
!  Calculate the point along the dogleg at which the quadratic is minimized.
!
    if ( sgnorm < delta ) then

      bnorm = enorm ( n, qtb )
      temp = ( bnorm / gnorm ) * ( bnorm / qnorm ) * ( sgnorm / delta )
      temp = temp - ( delta / qnorm ) * ( sgnorm / delta) ** 2 &
        + sqrt ( ( temp - ( delta / qnorm ) ) ** 2 &
        + ( 1.0D+00 - ( delta / qnorm ) ** 2 ) &
        * ( 1.0D+00 - ( sgnorm / delta ) ** 2 ) )

      alpha = ( ( delta / qnorm ) * ( 1.0D+00 - ( sgnorm / delta ) ** 2 ) ) &
        / temp

    end if

  end if
!
!  Form appropriate convex combination of the Gauss-Newton
!  direction and the scaled gradient direction.
!
  temp = ( 1.0D+00 - alpha ) * min ( sgnorm, delta )

  x(1:n) = temp * wa1(1:n) + alpha * x(1:n)

  return
end
function enorm ( n, x )

!*****************************************************************************80
!
!! enorm() computes the Euclidean norm of a vector.
!
!  Discussion:
!
!    The Euclidean norm is computed by accumulating the sum of
!    squares in three different sums.  The sums of squares for the
!    small and large components are scaled so that no overflows
!    occur.  Non-destructive underflows are permitted.  Underflows
!    and overflows do not occur in the computation of the unscaled
!    sum of squares for the intermediate components.
!
!    The definitions of small, intermediate and large components
!    depend on two constants, RDWARF and RGIANT.  The main
!    restrictions on these constants are that RDWARF^2 not
!    underflow and RGIANT^2 not overflow.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1
!    Argonne National Laboratory,
!    Argonne, Illinois.
!
!  Input:
!
!    integer N, is the length of the vector.
!
!    real ( kind = rk ) X(N), the vector whose norm is desired.
!
!  Output:
!
!    real ( kind = rk ) ENORM, the Euclidean norm of the vector.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) agiant
  real ( kind = rk ) enorm
  integer i
  real ( kind = rk ) rdwarf
  real ( kind = rk ) rgiant
  real ( kind = rk ) s1
  real ( kind = rk ) s2
  real ( kind = rk ) s3
  real ( kind = rk ) x(n)
  real ( kind = rk ) xabs
  real ( kind = rk ) x1max
  real ( kind = rk ) x3max

  rdwarf = sqrt ( tiny ( rdwarf ) )
  rgiant = sqrt ( huge ( rgiant ) )

  s1 = 0.0D+00
  s2 = 0.0D+00
  s3 = 0.0D+00
  x1max = 0.0D+00
  x3max = 0.0D+00
  agiant = rgiant / real ( n, kind = rk )

  do i = 1, n

    xabs = abs ( x(i) )

    if ( xabs <= rdwarf ) then

      if ( x3max < xabs ) then
        s3 = 1.0D+00 + s3 * ( x3max / xabs ) ** 2
        x3max = xabs
      else if ( xabs /= 0.0D+00 ) then
        s3 = s3 + ( xabs / x3max ) ** 2
      end if

    else if ( agiant <= xabs ) then

      if ( x1max < xabs ) then
        s1 = 1.0D+00 + s1 * ( x1max / xabs ) ** 2
        x1max = xabs
      else
        s1 = s1 + ( xabs / x1max ) ** 2
      end if

    else

      s2 = s2 + xabs ** 2

    end if

  end do
!
!  Calculation of norm.
!
  if ( s1 /= 0.0D+00 ) then

    enorm = x1max * sqrt ( s1 + ( s2 / x1max ) / x1max )

  else if ( s2 /= 0.0D+00 ) then

    if ( x3max <= s2 ) then
      enorm = sqrt ( s2 * ( 1.0D+00 + ( x3max / s2 ) * ( x3max * s3 ) ) )
    else
      enorm = sqrt ( x3max * ( ( s2 / x3max ) + ( x3max * s3 ) ) )
    end if

  else

    enorm = x3max * sqrt ( s3 )

  end if

  return
end
subroutine fdjac1 ( fcn, n, x, fvec, fjac, ldfjac, ml, mu, epsfcn )

!*****************************************************************************80
!
!! fdjac1() estimates a jacobian matrix using forward differences.
!
!  Discussion:
!
!    This function computes a forward-difference approximation
!    to the N by N jacobian matrix associated with a specified
!    problem of N functions in N variables. If the jacobian has
!    a banded form, then function evaluations are saved by only
!    approximating the nonzero terms.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, external FCN, the name of the user-supplied subroutine which
!    calculates the functions.  The routine should have the form:
!      subroutine fcn ( n, x, fvec )
!      integer n
!      real ( kind = rk ) fvec(n)
!      real ( kind = rk ) x(n)
!
!    Input, integer N, the number of functions and variables.
!
!    Input, real ( kind = rk ) X(N), the point where the jacobian is evaluated.
!
!    Input, real ( kind = rk ) FVEC(N), the functions evaluated at X.
!
!    Output, real ( kind = rk ) FJAC(LDFJAC,N), the N by N approximate
!    jacobian matrix.
!
!    Input, integer LDFJAC, the leading dimension of FJAC, which
!    must not be less than N.
!
!    Input, integer ML, MU, specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the
!    jacobian is not banded, set ML and MU to N-1.
!
!    Input, real ( kind = rk ) EPSFCN, is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer n

  real ( kind = rk ) eps
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  external fcn
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fvec(n)
  real ( kind = rk ) h
  integer i
  integer j
  integer k
  integer ml
  integer msum
  integer mu
  real ( kind = rk ) temp
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) x(n)

  epsmch = epsilon ( epsmch )

  eps = sqrt ( max ( epsfcn, epsmch ) )
  msum = ml + mu + 1
!
!  Computation of dense approximate jacobian.
!
  if ( n <= msum ) then

     do j = 1, n

        temp = x(j)
        h = eps * abs ( temp )
        if ( h == 0.0D+00 ) then
          h = eps
        end if

        x(j) = temp + h
        call fcn ( n, x, wa1 )

        x(j) = temp
        fjac(1:n,j) = ( wa1(1:n) - fvec(1:n) ) / h

     end do

  else
!
!  Computation of banded approximate jacobian.
!
     do k = 1, msum

        do j = k, n, msum
          wa2(j) = x(j)
          h = eps * abs ( wa2(j) )
          if ( h == 0.0D+00 ) then
            h = eps
          end if
          x(j) = wa2(j) + h
        end do

        call fcn ( n, x, wa1 )

        do j = k, n, msum

          x(j) = wa2(j)

          h = eps * abs ( wa2(j) )
          if ( h == 0.0D+00 ) then
            h = eps
          end if

          fjac(1:n,j) = 0.0D+00

          do i = 1, n
            if ( j - mu <= i .and. i <= j + ml ) then
              fjac(i,j) = ( wa1(i) - fvec(i) ) / h
            end if
          end do

        end do

     end do

  end if

  return
end
subroutine fdjac_bdf2 ( dydt, n, t1, x1, t2, x2, t3, x3, fvec, fjac, ldfjac, &
  ml, mu, epsfcn )

!*****************************************************************************80
!
!! fdjac_bdf2() estimates a jacobian matrix using forward differences.
!
!  Discussion:
!
!    This function computes a forward-difference approximation
!    to the N by N jacobian matrix associated with a specified
!    problem of N functions in N variables.  If the jacobian has
!    a banded form, then function evaluations are saved by only
!    approximating the nonzero terms.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    17 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(): the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) t1, x1(n), t2, x2(n), t3, x3(n): 
!    a sequence of three times and solution estimates.
!   
!    real ( kind = rk ) fvec(n): the functions evaluated at x3.
!
!    integer ldfjac: the leading dimension of FJAC, which
!    must not be less than N.
!
!    integer ml, mu: specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the
!    jacobian is not banded, set ML and MU to N-1.
!
!    real ( kind = rk ) epsfcn: is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!  Output:
!
!    real ( kind = rk ) fjac(ldfjac,n): the N by N approximate
!    jacobian matrix.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer n

  external dydt
  real ( kind = rk ) eps
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fvec(n)
  real ( kind = rk ) h
  integer i
  integer j
  integer k
  integer ml
  integer msum
  integer mu
  real ( kind = rk ) t1
  real ( kind = rk ) t2
  real ( kind = rk ) t3
  real ( kind = rk ) temp
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) x1(n)
  real ( kind = rk ) x2(n)
  real ( kind = rk ) x3(n)

  epsmch = epsilon ( epsmch )

  eps = sqrt ( max ( epsfcn, epsmch ) )
  msum = ml + mu + 1
!
!  Computation of dense approximate jacobian.
!
  if ( n <= msum ) then

    do j = 1, n

      temp = x3(j)
      h = eps * abs ( temp )
      if ( h == 0.0D+00 ) then
        h = eps
      end if

      x3(j) = temp + h
      call bdf2_residual ( dydt, n, t1, x1, t2, x2, t3, x3, wa1 )

      x3(j) = temp
      fjac(1:n,j) = ( wa1(1:n) - fvec(1:n) ) / h

    end do
!
!  Computation of banded approximate jacobian.
!
  else

    do k = 1, msum

      do j = k, n, msum
        wa2(j) = x3(j)
        h = eps * abs ( wa2(j) )
        if ( h == 0.0D+00 ) then
          h = eps
        end if
        x3(j) = wa2(j) + h
      end do

      call bdf2_residual ( dydt, n, t1, x1, t2, x2, t3, x3, wa1 )

      do j = k, n, msum

        x3(j) = wa2(j)

        h = eps * abs ( wa2(j) )
        if ( h == 0.0D+00 ) then
          h = eps
        end if

        fjac(1:n,j) = 0.0D+00

        do i = 1, n
          if ( j - mu <= i .and. i <= j + ml ) then
            fjac(i,j) = ( wa1(i) - fvec(i) ) / h
          end if
        end do

      end do

    end do

  end if

  return
end
subroutine fdjac_be ( dydt, n, to, xo, t, x, fvec, fjac, ldfjac, ml, &
  mu, epsfcn )

!*****************************************************************************80
!
!! fdjac_be() estimates a jacobian matrix using forward differences.
!
!  Discussion:
!
!    This function computes a forward-difference approximation
!    to the N by N jacobian matrix associated with a specified
!    problem of N functions in N variables.  If the jacobian has
!    a banded form, then function evaluations are saved by only
!    approximating the nonzero terms.
!
!    The original code fdjac1() was modified to deal with problems
!    involving a backward Euler residual.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    08 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(): the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) to, xo(n): the old time and solution.
!   
!    real ( kind = rk ) t, x(n): the new time and current solution estimate. 
!
!    real ( kind = rk ) fvec(n): the functions evaluated at X.
!
!    integer ldfjac: the leading dimension of FJAC, which
!    must not be less than N.
!
!    integer ml, mu: specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the
!    jacobian is not banded, set ML and MU to N-1.
!
!    real ( kind = rk ) epsfcn: is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!  Output:
!
!    real ( kind = rk ) fjac(ldfjac,n): the N by N approximate
!    jacobian matrix.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer n

  external dydt
  real ( kind = rk ) eps
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fvec(n)
  real ( kind = rk ) h
  integer i
  integer j
  integer k
  integer ml
  integer msum
  integer mu
  real ( kind = rk ) t
  real ( kind = rk ) temp
  real ( kind = rk ) to
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) x(n)
  real ( kind = rk ) xo(n)

  epsmch = epsilon ( epsmch )

  eps = sqrt ( max ( epsfcn, epsmch ) )
  msum = ml + mu + 1
!
!  Computation of dense approximate jacobian.
!
  if ( n <= msum ) then

    do j = 1, n

      temp = x(j)
      h = eps * abs ( temp )
      if ( h == 0.0D+00 ) then
        h = eps
      end if

      x(j) = temp + h
      call backward_euler_residual ( dydt, n, to, xo, t, x, wa1 )

      x(j) = temp
      fjac(1:n,j) = ( wa1(1:n) - fvec(1:n) ) / h

    end do
!
!  Computation of banded approximate jacobian.
!
  else

    do k = 1, msum

      do j = k, n, msum
        wa2(j) = x(j)
        h = eps * abs ( wa2(j) )
        if ( h == 0.0D+00 ) then
          h = eps
        end if
        x(j) = wa2(j) + h
      end do

      call backward_euler_residual ( dydt, n, to, xo, t, x, wa1 )

      do j = k, n, msum

        x(j) = wa2(j)

        h = eps * abs ( wa2(j) )
        if ( h == 0.0D+00 ) then
          h = eps
        end if

        fjac(1:n,j) = 0.0D+00

        do i = 1, n
          if ( j - mu <= i .and. i <= j + ml ) then
            fjac(i,j) = ( wa1(i) - fvec(i) ) / h
          end if
        end do

      end do

    end do

  end if

  return
end
subroutine fdjac_tr ( dydt, n, to, xo, tn, xn, fvec, fjac, ldfjac, ml, &
  mu, epsfcn )

!*****************************************************************************80
!
!! fdjac_tr() estimates a jacobian matrix using forward differences.
!
!  Discussion:
!
!    This function computes a forward-difference approximation
!    to the N by N jacobian matrix associated with a specified
!    problem of N functions in N variables.  If the jacobian has
!    a banded form, then function evaluations are saved by only
!    approximating the nonzero terms.
!
!    The original code fdjac1() was modified to deal with problems
!    involving an implicit trapezoidal ODE residual.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    15 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(): the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) to, xo(n): the old time and solution.
!   
!    real ( kind = rk ) tn, xn(n): the new time and current solution estimate. 
!
!    real ( kind = rk ) fvec(n): the functions evaluated at X.
!
!    integer ldfjac: the leading dimension of FJAC, which
!    must not be less than N.
!
!    integer ml, mu: specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the
!    jacobian is not banded, set ML and MU to N-1.
!
!    real ( kind = rk ) epsfcn: is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!  Output:
!
!    real ( kind = rk ) fjac(ldfjac,n): the N by N approximate
!    jacobian matrix.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer n

  external dydt
  real ( kind = rk ) eps
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fvec(n)
  real ( kind = rk ) h
  integer i
  integer j
  integer k
  integer ml
  integer msum
  integer mu
  real ( kind = rk ) temp
  real ( kind = rk ) tn
  real ( kind = rk ) to
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) xn(n)
  real ( kind = rk ) xo(n)

  epsmch = epsilon ( epsmch )

  eps = sqrt ( max ( epsfcn, epsmch ) )
  msum = ml + mu + 1
!
!  Computation of dense approximate jacobian.
!
  if ( n <= msum ) then

    do j = 1, n

      temp = xn(j)
      h = eps * abs ( temp )
      if ( h == 0.0D+00 ) then
        h = eps
      end if

      xn(j) = temp + h
      call trapezoidal_residual ( dydt, n, to, xo, tn, xn, wa1 )

      xn(j) = temp
      fjac(1:n,j) = ( wa1(1:n) - fvec(1:n) ) / h

    end do
!
!  Computation of banded approximate jacobian.
!
  else

    do k = 1, msum

      do j = k, n, msum
        wa2(j) = xn(j)
        h = eps * abs ( wa2(j) )
        if ( h == 0.0D+00 ) then
          h = eps
        end if
        xn(j) = wa2(j) + h
      end do

      call trapezoidal_residual ( dydt, n, to, xo, tn, xn, wa1 )

      do j = k, n, msum

        xn(j) = wa2(j)

        h = eps * abs ( wa2(j) )
        if ( h == 0.0D+00 ) then
          h = eps
        end if

        fjac(1:n,j) = 0.0D+00

        do i = 1, n
          if ( j - mu <= i .and. i <= j + ml ) then
            fjac(i,j) = ( wa1(i) - fvec(i) ) / h
          end if
        end do

      end do

    end do

  end if

  return
end
subroutine fsolve ( fcn, n, x, fvec, tol, info )

!*****************************************************************************80
!
!! fsolve() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  This is done by using the
!    more general nonlinear equation solver HYBRD.  The user provides a
!    subroutine which calculates the functions.  
!
!    The jacobian is calculated by a forward-difference approximation.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    07 April 2021
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external FCN, the user subroutine which calculates the functions.  
!    The routine should have the form:
!      subroutine fcn ( n, x, fvec )
!      integer n
!      real ( kind = rk ) fvec(n)
!      real ( kind = rk ) x(n)
!
!    integer N, the number of functions and variables.
!
!    real ( kind = rk ) X(N), an initial estimate of the solution vector.  
!
!    real ( kind = rk ) TOL.  Satisfactory termination occurs when the algorithm
!    estimates that the relative error between X and the solution is at
!    most TOL.  TOL should be nonnegative.
!
!  Output:
!
!    real ( kind = rk ) X(N), the estimate of the solution vector.
!
!    real ( kind = rk ) FVEC(N), the functions evaluated at the output X.
!
!    integer INFO, error flag.
!    0, improper input parameters.
!    1, algorithm estimates that the relative error between X and the
!       solution is at most TOL.
!    2, number of calls to FCN has reached or exceeded 200*(N+1).
!    3, TOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, the iteration is not making good progress.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) diag(n)
  real ( kind = rk ) epsfcn
  real ( kind = rk ) factor
  external fcn
  real ( kind = rk ) fjac(n,n)
  real ( kind = rk ) fvec(n)
  integer info
  integer ldfjac
  integer lr
  integer maxfev
  integer ml
  integer mode
  integer mu
  integer nfev
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r((n*(n+1))/2)
  real ( kind = rk ) tol
  real ( kind = rk ) x(n)
  real ( kind = rk ) xtol

  if ( n <= 0 ) then
    info = 0
    return
  end if

  if ( tol < 0.0D+00 ) then
    info = 0
    return
  end if

  xtol = tol
  maxfev = 200 * ( n + 1 )
  ml = n - 1
  mu = n - 1
  epsfcn = 0.0D+00
  diag(1:n) = 1.0D+00
  mode = 2
  factor = 100.0D+00
  info = 0
  nfev = 0
  fjac(1:n,1:n) = 0.0D+00
  ldfjac = n
  r(1:(n*(n+1))/2) = 0.0D+00
  lr = ( n * ( n + 1 ) ) / 2
  qtf(1:n) = 0.0D+00

  call hybrd ( fcn, n, x, fvec, xtol, maxfev, ml, mu, epsfcn, diag, mode, &
    factor, info, nfev, fjac, ldfjac, r, lr, qtf )

  if ( info == 5 ) then
    info = 4
  end if

  return
end
subroutine fsolve_bdf2 ( dydt, n, t1, x1, t2, x2, t3, x3, fvec, tol, info )

!*****************************************************************************80
!
!! fsolve_bdf2() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  This is done by using the
!    more general nonlinear equation solver hybrd_bdf2().  The user provides a
!    subroutine which calculates the functions.  
!
!    The jacobian is calculated by a forward-difference approximation.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    17 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(), the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) t1, x1(n), t2, x2(n), t3, x3(n): 
!    a sequence of three times and solution estimates.
!
!    real ( kind = rk ) tol:  Satisfactory termination occurs when the algorithm
!    estimates that the relative error between X and the solution is at
!    most TOL.  TOL should be nonnegative.
!
!  Output:
!
!    real ( kind = rk ) x3(n): the new estimate of the solution vector.
!
!    real ( kind = rk ) fvec(n): the residuals evaluated at the output x.
!
!    integer info: a status flag.  A value of 1 represents success.
!    0, improper input parameters.
!    1, algorithm estimates that the relative error between X and the
!       solution is at most TOL.
!    2, number of calls to derivative has reached or exceeded 200*(N+1).
!    3, TOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, the iteration is not making good progress.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) diag(n)
  external dydt
  real ( kind = rk ) epsfcn
  real ( kind = rk ) factor
  real ( kind = rk ) fjac(n,n)
  real ( kind = rk ) fvec(n)
  integer info
  integer ldfjac
  integer lr
  integer maxfev
  integer ml
  integer mode
  integer mu
  integer nfev
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r((n*(n+1))/2)
  real ( kind = rk ) t1
  real ( kind = rk ) t2
  real ( kind = rk ) t3
  real ( kind = rk ) tol
  real ( kind = rk ) x1(n)
  real ( kind = rk ) x2(n)
  real ( kind = rk ) x3(n)
  real ( kind = rk ) xtol

  if ( n <= 0 ) then
    info = 0
    return
  end if

  if ( tol < 0.0D+00 ) then
    info = 0
    return
  end if

  xtol = tol
  maxfev = 200 * ( n + 1 )
  ml = n - 1
  mu = n - 1
  epsfcn = 0.0D+00
  diag(1:n) = 1.0D+00
  mode = 2
  factor = 100.0D+00
  info = 0
  nfev = 0
  fjac(1:n,1:n) = 0.0D+00
  ldfjac = n
  r(1:(n*(n+1))/2) = 0.0D+00
  lr = ( n * ( n + 1 ) ) / 2
  qtf(1:n) = 0.0D+00

  call hybrd_bdf2 ( dydt, n, t1, x1, t2, x2, t3, x3, fvec, xtol, maxfev, &
    ml, mu, epsfcn, diag, mode, factor, info, nfev, fjac, ldfjac, r, lr, qtf )

  if ( info == 5 ) then
    info = 4
  end if

  return
end
subroutine fsolve_be ( dydt, n, to, xo, t, x, fvec, tol, info )

!*****************************************************************************80
!
!! fsolve_be() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  This is done by using the
!    more general nonlinear equation solver hybrd_be().  The user provides a
!    subroutine which calculates the functions.  
!
!    The jacobian is calculated by a forward-difference approximation.
!
!    The original code fsolve() was modified to deal with problems
!    involving a backward Euler residual.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    08 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(), the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) to, xo(n): the old time and solution.
!   
!    real ( kind = rk ) t, x(n): the new time and current solution estimate. 
!
!    real ( kind = rk ) tol:  Satisfactory termination occurs when the algorithm
!    estimates that the relative error between X and the solution is at
!    most TOL.  TOL should be nonnegative.
!
!  Output:
!
!    real ( kind = rk ) x(n): the new estimate of the solution vector.
!
!    real ( kind = rk ) fvec(n): the residuals evaluated at the output x.
!
!    integer info: a status flag.  A value of 1 represents success.
!    0, improper input parameters.
!    1, algorithm estimates that the relative error between X and the
!       solution is at most TOL.
!    2, number of calls to derivative has reached or exceeded 200*(N+1).
!    3, TOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, the iteration is not making good progress.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) diag(n)
  external dydt
  real ( kind = rk ) epsfcn
  real ( kind = rk ) factor
  real ( kind = rk ) fjac(n,n)
  real ( kind = rk ) fvec(n)
  integer info
  integer ldfjac
  integer lr
  integer maxfev
  integer ml
  integer mode
  integer mu
  integer nfev
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r((n*(n+1))/2)
  real ( kind = rk ) t
  real ( kind = rk ) to
  real ( kind = rk ) tol
  real ( kind = rk ) x(n)
  real ( kind = rk ) xo(n)
  real ( kind = rk ) xtol

  if ( n <= 0 ) then
    info = 0
    return
  end if

  if ( tol < 0.0D+00 ) then
    info = 0
    return
  end if

  xtol = tol
  maxfev = 200 * ( n + 1 )
  ml = n - 1
  mu = n - 1
  epsfcn = 0.0D+00
  diag(1:n) = 1.0D+00
  mode = 2
  factor = 100.0D+00
  info = 0
  nfev = 0
  fjac(1:n,1:n) = 0.0D+00
  ldfjac = n
  r(1:(n*(n+1))/2) = 0.0D+00
  lr = ( n * ( n + 1 ) ) / 2
  qtf(1:n) = 0.0D+00

  call hybrd_be ( dydt, n, to, xo, t, x, fvec, xtol, maxfev, ml, mu, &
    epsfcn, diag, mode, factor, info, nfev, fjac, ldfjac, r, lr, qtf )

  if ( info == 5 ) then
    info = 4
  end if

  return
end
subroutine fsolve_tr ( dydt, n, to, xo, tn, xn, fvec, tol, info )

!*****************************************************************************80
!
!! fsolve_tr() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  This is done by using the
!    more general nonlinear equation solver hybrd_be().  The user provides a
!    subroutine which calculates the functions.  
!
!    The jacobian is calculated by a forward-difference approximation.
!
!    The original code fsolve() was modified to deal with problems
!    involving an implicit trapezoidal ODE residual.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    15 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(), the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) to, xo(n): the old time and solution.
!   
!    real ( kind = rk ) tn, xn(n): the new time and current solution estimate. 
!
!    real ( kind = rk ) tol:  Satisfactory termination occurs when the algorithm
!    estimates that the relative error between X and the solution is at
!    most TOL.  TOL should be nonnegative.
!
!  Output:
!
!    real ( kind = rk ) xn(n): the new estimate of the solution vector.
!
!    real ( kind = rk ) fvec(n): the residuals evaluated at the output xn.
!
!    integer info: a status flag.  A value of 1 represents success.
!    0, improper input parameters.
!    1, algorithm estimates that the relative error between X and the
!       solution is at most TOL.
!    2, number of calls to derivative has reached or exceeded 200*(N+1).
!    3, TOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, the iteration is not making good progress.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) diag(n)
  external dydt
  real ( kind = rk ) epsfcn
  real ( kind = rk ) factor
  real ( kind = rk ) fjac(n,n)
  real ( kind = rk ) fvec(n)
  integer info
  integer ldfjac
  integer lr
  integer maxfev
  integer ml
  integer mode
  integer mu
  integer nfev
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r((n*(n+1))/2)
  real ( kind = rk ) tn
  real ( kind = rk ) to
  real ( kind = rk ) tol
  real ( kind = rk ) xn(n)
  real ( kind = rk ) xo(n)
  real ( kind = rk ) xtol

  if ( n <= 0 ) then
    info = 0
    return
  end if

  if ( tol < 0.0D+00 ) then
    info = 0
    return
  end if

  xtol = tol
  maxfev = 200 * ( n + 1 )
  ml = n - 1
  mu = n - 1
  epsfcn = 0.0D+00
  diag(1:n) = 1.0D+00
  mode = 2
  factor = 100.0D+00
  info = 0
  nfev = 0
  fjac(1:n,1:n) = 0.0D+00
  ldfjac = n
  r(1:(n*(n+1))/2) = 0.0D+00
  lr = ( n * ( n + 1 ) ) / 2
  qtf(1:n) = 0.0D+00

  call hybrd_tr ( dydt, n, to, xo, tn, xn, fvec, xtol, maxfev, ml, mu, &
    epsfcn, diag, mode, factor, info, nfev, fjac, ldfjac, r, lr, qtf )

  if ( info == 5 ) then
    info = 4
  end if

  return
end
subroutine hybrd ( fcn, n, x, fvec, xtol, maxfev, ml, mu, epsfcn, diag, mode, &
  factor, info, nfev, fjac, ldfjac, r, lr, qtf )

!*****************************************************************************80
!
!! hybrd() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  The user must provide a
!    subroutine which calculates the functions.  
!
!    The jacobian is then calculated by a forward-difference approximation.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, external FCN, the name of the user-supplied subroutine which
!    calculates the functions.  The routine should have the form:
!      subroutine fcn ( n, x, fvec )
!      integer n
!      real ( kind = rk ) fvec(n)
!      real ( kind = rk ) x(n)
!
!    Input, integer N, the number of functions and variables.
!
!    Input/output, real ( kind = rk ) X(N).  On input, X must contain an initial
!    estimate of the solution vector.  On output X contains the final
!    estimate of the solution vector.
!
!    Output, real ( kind = rk ) FVEC(N), the functions evaluated at the output X.
!
!    Input, real ( kind = rk ) XTOL.  Termination occurs when the relative error
!    between two consecutive iterates is at most XTOL.  XTOL should be
!    nonnegative.
!
!    Input, integer MAXFEV.  Termination occurs when the number of
!    calls to FCN is at least MAXFEV by the end of an iteration.
!
!    Input, integer ML, MU, specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the jacobian
!    is not banded, set ML and MU to at least n - 1.
!
!    Input, real ( kind = rk ) EPSFCN, is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!    Input/output, real ( kind = rk ) DIAG(N).  If MODE = 1, then DIAG is set
!    internally.  If MODE = 2, then DIAG must contain positive entries that
!    serve as multiplicative scale factors for the variables.
!
!    Input, integer MODE, scaling option.
!    1, variables will be scaled internally.
!    2, scaling is specified by the input DIAG vector.
!
!    Input, real ( kind = rk ) FACTOR, determines the initial step bound.  This
!    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
!    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
!    in the interval (0.1, 100) with 100 the recommended value.
!
!    Output, integer INFO, error flag. 
!    0, improper input parameters.
!    1, relative error between two consecutive iterates is at most XTOL.
!    2, number of calls to FCN has reached or exceeded MAXFEV.
!    3, XTOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, iteration is not making good progress, as measured by the improvement
!       from the last five jacobian evaluations.
!    5, iteration is not making good progress, as measured by the improvement
!       from the last ten iterations.
!
!    Output, integer NFEV, the number of calls to FCN.
!
!    Output, real ( kind = rk ) FJAC(LDFJAC,N), an N by N array which contains
!    the orthogonal matrix Q produced by the QR factorization of the final
!    approximate jacobian.
!
!    Input, integer LDFJAC, the leading dimension of FJAC.
!    LDFJAC must be at least N.
!
!    Output, real ( kind = rk ) R(LR), the upper triangular matrix produced by
!    the QR factorization of the final approximate jacobian, stored rowwise.
!
!    Input, integer LR, the size of the R array, which must be no
!    less than (N*(N+1))/2.
!
!    Output, real ( kind = rk ) QTF(N), contains the vector Q'*FVEC.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer lr
  integer n

  real ( kind = rk ) actred
  real ( kind = rk ) delta
  real ( kind = rk ) diag(n)
  real ( kind = rk ) enorm
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) factor
  external fcn
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fnorm
  real ( kind = rk ) fnorm1
  real ( kind = rk ) fvec(n)
  integer i
  integer info
  integer iter
  integer iwa(1)
  integer j
  logical jeval
  integer l
  integer maxfev
  integer ml
  integer mode
  integer msum
  integer mu
  integer ncfail
  integer nslow1
  integer nslow2
  integer ncsuc
  integer nfev
  logical pivot
  real ( kind = rk ) pnorm
  real ( kind = rk ) prered
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r(lr)
  real ( kind = rk ) ratio
  logical sing
  real ( kind = rk ) sum2
  real ( kind = rk ) temp
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) wa3(n)
  real ( kind = rk ) wa4(n)
  real ( kind = rk ) x(n)
  real ( kind = rk ) xnorm
  real ( kind = rk ) xtol

  epsmch = epsilon ( epsmch )

  info = 0
  nfev = 0
!
!  Check the input parameters for errors.
!
  if ( n <= 0 ) then
    return
  else if ( xtol < 0.0D+00 ) then
    return
  else if ( maxfev <= 0 ) then
    return
  else if ( ml < 0 ) then
    return
  else if ( mu < 0 ) then
    return
  else if ( factor <= 0.0D+00 ) then
    return
  else if ( ldfjac < n ) then
    return
  else if ( lr < ( n * ( n + 1 ) ) / 2 ) then
    return
  end if

  if ( mode == 2 ) then

    do j = 1, n
      if ( diag(j) <= 0.0D+00 ) then
        return
      end if
    end do

  end if
!
!  Evaluate the function at the starting point
!  and calculate its norm.
!
  call fcn ( n, x, fvec )
  nfev = 1

  fnorm = enorm ( n, fvec )
!
!  Determine the number of calls to FCN needed to compute the jacobian matrix.
!
  msum = min ( ml + mu + 1, n )
!
!  Initialize iteration counter and monitors.
!
  iter = 1
  ncsuc = 0
  ncfail = 0
  nslow1 = 0
  nslow2 = 0
!
!  Beginning of the outer loop.
!
30 continue

    jeval = .true.
!
!  Calculate the jacobian matrix.
!
    call fdjac1 ( fcn, n, x, fvec, fjac, ldfjac, ml, mu, epsfcn )

    nfev = nfev + msum
!
!  Compute the QR factorization of the jacobian.
!
    pivot = .false.
    call qrfac ( n, n, fjac, ldfjac, pivot, iwa, 1, wa1, wa2 )
!
!  On the first iteration, if MODE is 1, scale according
!  to the norms of the columns of the initial jacobian.
!
    if ( iter == 1 ) then

      if ( mode /= 2 ) then

        diag(1:n) = wa2(1:n)
        do j = 1, n
          if ( wa2(j) == 0.0D+00 ) then
            diag(j) = 1.0D+00
          end if
        end do

      end if
!
!  On the first iteration, calculate the norm of the scaled X
!  and initialize the step bound DELTA.
!
      wa3(1:n) = diag(1:n) * x(1:n)
      xnorm = enorm ( n, wa3 )
      delta = factor * xnorm
      if ( delta == 0.0D+00 ) then
        delta = factor
      end if

    end if
!
!  Form Q' * FVEC and store in QTF.
!
     qtf(1:n) = fvec(1:n)

     do j = 1, n

       if ( fjac(j,j) /= 0.0D+00 ) then
         temp = - dot_product ( qtf(j:n), fjac(j:n,j) ) / fjac(j,j)
         qtf(j:n) = qtf(j:n) + fjac(j:n,j) * temp
       end if

     end do
!
!  Copy the triangular factor of the QR factorization into R.
!
     sing = .false.

     do j = 1, n
        l = j
        do i = 1, j - 1
          r(l) = fjac(i,j)
          l = l + n - i
        end do
        r(l) = wa1(j)
        if ( wa1(j) == 0.0D+00 ) then
          sing = .true.
        end if
     end do
!
!  Accumulate the orthogonal factor in FJAC.
!
     call qform ( n, n, fjac, ldfjac )
!
!  Rescale if necessary.
!
     if ( mode /= 2 ) then
       do j = 1, n
         diag(j) = max ( diag(j), wa2(j) )
       end do
     end if
!
!  Beginning of the inner loop.
!
180    continue
!
!  Determine the direction P.
!
        call dogleg ( n, r, lr, diag, qtf, delta, wa1 )
!
!  Store the direction P and X + P.
!  Calculate the norm of P.
!
        wa1(1:n) = - wa1(1:n)
        wa2(1:n) = x(1:n) + wa1(1:n)
        wa3(1:n) = diag(1:n) * wa1(1:n)

        pnorm = enorm ( n, wa3 )
!
!  On the first iteration, adjust the initial step bound.
!
        if ( iter == 1 ) then
          delta = min ( delta, pnorm )
        end if
!
!  Evaluate the function at X + P and calculate its norm.
!
        call fcn ( n, wa2, wa4 )
        nfev = nfev + 1
        fnorm1 = enorm ( n, wa4 )
!
!  Compute the scaled actual reduction.
!
        actred = -1.0D+00
        if ( fnorm1 < fnorm ) then
          actred = 1.0D+00 - ( fnorm1 / fnorm ) ** 2
        endif
!
!  Compute the scaled predicted reduction.
!
        l = 1
        do i = 1, n
          sum2 = 0.0D+00
          do j = i, n
            sum2 = sum2 + r(l) * wa1(j)
            l = l + 1
          end do
          wa3(i) = qtf(i) + sum2
        end do

        temp = enorm ( n, wa3 )
        prered = 0.0D+00
        if ( temp < fnorm ) then
          prered = 1.0D+00 - ( temp / fnorm ) ** 2
        end if
!
!  Compute the ratio of the actual to the predicted reduction.
!
        ratio = 0.0D+00
        if ( 0.0D+00 < prered ) then
          ratio = actred / prered
        end if
!
!  Update the step bound.
!
        if ( ratio < 0.1D+00 ) then

          ncsuc = 0
          ncfail = ncfail + 1
          delta = 0.5D+00 * delta

        else

          ncfail = 0
          ncsuc = ncsuc + 1

          if ( 0.5D+00 <= ratio .or. 1 < ncsuc ) then
            delta = max ( delta, pnorm / 0.5D+00 )
          end if

          if ( abs ( ratio - 1.0D+00 ) <= 0.1D+00 ) then
            delta = pnorm / 0.5D+00
          end if

        end if
!
!  Test for successful iteration.
!
!  Successful iteration.
!  Update X, FVEC, and their norms.
!
        if ( 0.0001D+00 <= ratio ) then
          x(1:n) = wa2(1:n)
          wa2(1:n) = diag(1:n) * x(1:n)
          fvec(1:n) = wa4(1:n)
          xnorm = enorm ( n, wa2 )
          fnorm = fnorm1
          iter = iter + 1
        end if
!
!  Determine the progress of the iteration.
!
        nslow1 = nslow1 + 1
        if ( 0.001D+00 <= actred ) then
          nslow1 = 0
        end if

        if ( jeval ) then
          nslow2 = nslow2 + 1
        end if

        if ( 0.1D+00 <= actred ) then
          nslow2 = 0
        end if
!
!  Test for convergence.
!
        if ( delta <= xtol * xnorm .or. fnorm == 0.0D+00 ) then
          info = 1
        end if

        if ( info /= 0 ) then
          return
        end if
!
!  Tests for termination and stringent tolerances.
!
        if ( maxfev <= nfev ) then
          info = 2
        end if

        if ( 0.1D+00 * max ( 0.1D+00 * delta, pnorm ) <= epsmch * xnorm ) then
          info = 3
        end if

        if ( nslow2 == 5 ) then
          info = 4
        end if

        if ( nslow1 == 10 ) then
          info = 5
        end if

        if ( info /= 0 ) then
          return
        end if
!
!  Criterion for recalculating jacobian approximation
!  by forward differences.
!
        if ( ncfail == 2 ) then
          go to 290
        end if
!
!  Calculate the rank one modification to the jacobian
!  and update QTF if necessary.
!
        do j = 1, n
          sum2 = dot_product ( wa4(1:n), fjac(1:n,j) )
          wa2(j) = ( sum2 - wa3(j) ) / pnorm
          wa1(j) = diag(j) * ( ( diag(j) * wa1(j) ) / pnorm )
          if ( 0.0001D+00 <= ratio ) then
            qtf(j) = sum2
          end if
        end do
!
!  Compute the QR factorization of the updated jacobian.
!
        call r1updt ( n, n, r, lr, wa1, wa2, wa3, sing )
        call r1mpyq ( n, n, fjac, ldfjac, wa2, wa3 )
        call r1mpyq ( 1, n, qtf, 1, wa2, wa3 )
!
!  End of the inner loop.
!
        jeval = .false.
        go to 180

  290   continue
!
!  End of the outer loop.
!
     go to 30

  return
end
subroutine hybrd_bdf2 ( dydt, n, t1, x1, t2, x2, t3, x3, fvec, xtol, maxfev, &
  ml, mu, epsfcn, diag, mode, factor, info, nfev, fjac, ldfjac, r, lr, qtf )

!*****************************************************************************80
!
!! hybrd_bdf2() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  The user must provide a
!    subroutine which calculates the functions.  
!
!    The jacobian is then calculated by a forward-difference approximation.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    17 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(), the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(n)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(n)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) t1, x1(n), t2, x2(n), t3, x3(n): 
!    a sequence of three times and solution estimates.
!
!    real ( kind = rk ) xtol: Termination occurs when the relative error
!    between two consecutive iterates is at most XTOL.  XTOL should be
!    nonnegative.
!
!    integer maxfev: Termination occurs when the number of
!    calls to the derivative code is at least MAXFEV by the end of an iteration.
!
!    integer ml, mu: specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the jacobian
!    is not banded, set ML and MU to at least n - 1.
!
!    real ( kind = rk ) epsfcn: is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!    real ( kind = rk ) diag(n): multiplicative scale factors for the 
!    variables.  Only needed as input if MODE = 2.  
!
!    integer mode: scaling option.
!    1, variables will be scaled internally.
!    2, scaling is specified by the input DIAG vector.
!
!    real ( kind = rk ) factor: determines the initial step bound.  This
!    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
!    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
!    in the interval (0.1, 100) with 100 the recommended value.
!
!    integer ldfjac: the leading dimension of FJAC.
!    LDFJAC must be at least N.
!
!    integer lr: the size of the R array, which must be no
!    less than (N*(N+1))/2.
!
!  Output:
!
!    real ( kind = rk ) x3(n): the final estimate of the solution vector.
!
!    real ( kind = rk ) fvec(n): the functions evaluated at the output x.
!
!    real ( kind = rk ) diag(n): multiplicative scale factors for the 
!    variables.  Set internally if MODE = 1.
!    
!    integer info: status flag.  A value of 1 indicates success. 
!    0, improper input parameters.
!    1, relative error between two consecutive iterates is at most XTOL.
!    2, number of calls to derivative has reached or exceeded MAXFEV.
!    3, XTOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, iteration is not making good progress, as measured by the improvement
!       from the last five jacobian evaluations.
!    5, iteration is not making good progress, as measured by the improvement
!       from the last ten iterations.
!
!    integer nfev: the number of calls to the derivative function.
!
!    real ( kind = rk ) fjac(ldfjac,n): an N by N array which contains
!    the orthogonal matrix Q produced by the QR factorization of the final
!    approximate jacobian.
!
!    real ( kind = rk ) r(lr): the upper triangular matrix produced by
!    the QR factorization of the final approximate jacobian, stored rowwise.
!
!    real ( kind = rk ) qtf(n): contains the vector Q'*FVEC.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer lr
  integer n

  real ( kind = rk ) actred
  real ( kind = rk ) delta
  real ( kind = rk ) diag(n)
  external dydt
  real ( kind = rk ) enorm
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) factor
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fnorm
  real ( kind = rk ) fnorm1
  real ( kind = rk ) fvec(n)
  integer i
  integer info
  integer iter
  integer iwa(1)
  integer j
  logical jeval
  integer l
  integer maxfev
  integer ml
  integer mode
  integer msum
  integer mu
  integer ncfail
  integer ncsuc
  integer nfev
  integer nslow1
  integer nslow2
  logical pivot
  real ( kind = rk ) pnorm
  real ( kind = rk ) prered
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r(lr)
  real ( kind = rk ) ratio
  logical sing
  real ( kind = rk ) sum2
  real ( kind = rk ) t1
  real ( kind = rk ) t2
  real ( kind = rk ) t3
  real ( kind = rk ) temp
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) wa3(n)
  real ( kind = rk ) wa4(n)
  real ( kind = rk ) x1(n)
  real ( kind = rk ) x2(n)
  real ( kind = rk ) x3(n)
  real ( kind = rk ) xnorm
  real ( kind = rk ) xtol

  epsmch = epsilon ( epsmch )

  info = 0
  nfev = 0
!
!  Check the input parameters for errors.
!
  if ( n <= 0 ) then
    return
  else if ( xtol < 0.0D+00 ) then
    return
  else if ( maxfev <= 0 ) then
    return
  else if ( ml < 0 ) then
    return
  else if ( mu < 0 ) then
    return
  else if ( factor <= 0.0D+00 ) then
    return
  else if ( ldfjac < n ) then
    return
  else if ( lr < ( n * ( n + 1 ) ) / 2 ) then
    return
  end if

  if ( mode == 2 ) then

    do j = 1, n
      if ( diag(j) <= 0.0D+00 ) then
        return
      end if
    end do

  end if
!
!  Evaluate the function at the starting point
!  and calculate its norm.
!
  call bdf2_residual ( dydt, n, t1, x1, t2, x2, t3, x3, fvec )
  nfev = 1

  fnorm = enorm ( n, fvec )
!
!  Determine the number of calls needed to compute the jacobian matrix.
!
  msum = min ( ml + mu + 1, n )
!
!  Initialize iteration counter and monitors.
!
  iter = 1
  ncsuc = 0
  ncfail = 0
  nslow1 = 0
  nslow2 = 0
!
!  Beginning of the outer loop.
!
  do

    jeval = .true.
!
!  Calculate the jacobian matrix.
!
    call fdjac_bdf2 ( dydt, n, t1, x1, t2, x2, t3, x3, fvec, fjac, ldfjac, &
      ml, mu, epsfcn )

    nfev = nfev + msum
!
!  Compute the QR factorization of the jacobian.
!
    pivot = .false.
    call qrfac ( n, n, fjac, ldfjac, pivot, iwa, 1, wa1, wa2 )
!
!  On the first iteration, if MODE is 1, scale according
!  to the norms of the columns of the initial jacobian.
!
    if ( iter == 1 ) then

      if ( mode /= 2 ) then

        diag(1:n) = wa2(1:n)
        do j = 1, n
          if ( wa2(j) == 0.0D+00 ) then
            diag(j) = 1.0D+00
          end if
        end do

      end if
!
!  On the first iteration, calculate the norm of the scaled X
!  and initialize the step bound DELTA.
!
      wa3(1:n) = diag(1:n) * x3(1:n)
      xnorm = enorm ( n, wa3 )
      delta = factor * xnorm
      if ( delta == 0.0D+00 ) then
        delta = factor
      end if

    end if
!
!  Form Q' * FVEC and store in QTF.
!
    qtf(1:n) = fvec(1:n)

    do j = 1, n

      if ( fjac(j,j) /= 0.0D+00 ) then
        temp = - dot_product ( qtf(j:n), fjac(j:n,j) ) / fjac(j,j)
        qtf(j:n) = qtf(j:n) + fjac(j:n,j) * temp
      end if

    end do
!
!  Copy the triangular factor of the QR factorization into R.
!
    sing = .false.

    do j = 1, n
      l = j
      do i = 1, j - 1
        r(l) = fjac(i,j)
        l = l + n - i
      end do
      r(l) = wa1(j)
      if ( wa1(j) == 0.0D+00 ) then
        sing = .true.
      end if
    end do
!
!  Accumulate the orthogonal factor in FJAC.
!
    call qform ( n, n, fjac, ldfjac )
!
!  Rescale if necessary.
!
    if ( mode /= 2 ) then
      do j = 1, n
        diag(j) = max ( diag(j), wa2(j) )
      end do
    end if
!
!  Beginning of the inner loop.
!
    do
!
!  Determine the direction P.
!
      call dogleg ( n, r, lr, diag, qtf, delta, wa1 )
!
!  Store the direction P and X + P.
!  Calculate the norm of P.
!
      wa1(1:n) = - wa1(1:n)
      wa2(1:n) = x3(1:n) + wa1(1:n)
      wa3(1:n) = diag(1:n) * wa1(1:n)

      pnorm = enorm ( n, wa3 )
!
!  On the first iteration, adjust the initial step bound.
!
      if ( iter == 1 ) then
        delta = min ( delta, pnorm )
      end if
!
!  Evaluate the function at X + P and calculate its norm.
!
      call bdf2_residual ( dydt, n, t1, x1, t2, x2, t3, wa2, wa4 )
      nfev = nfev + 1
      fnorm1 = enorm ( n, wa4 )
!
!  Compute the scaled actual reduction.
!
      actred = -1.0D+00
      if ( fnorm1 < fnorm ) then
        actred = 1.0D+00 - ( fnorm1 / fnorm ) ** 2
      end if
!
!  Compute the scaled predicted reduction.
!
      l = 1
      do i = 1, n
        sum2 = 0.0D+00
        do j = i, n
          sum2 = sum2 + r(l) * wa1(j)
          l = l + 1
        end do
        wa3(i) = qtf(i) + sum2
      end do

      temp = enorm ( n, wa3 )
      prered = 0.0D+00
      if ( temp < fnorm ) then
        prered = 1.0D+00 - ( temp / fnorm ) ** 2
      end if
!
!  Compute the ratio of the actual to the predicted reduction.
!
      ratio = 0.0D+00
      if ( 0.0D+00 < prered ) then
        ratio = actred / prered
      end if
!
!  Update the step bound.
!
      if ( ratio < 0.1D+00 ) then

        ncsuc = 0
        ncfail = ncfail + 1
        delta = 0.5D+00 * delta

      else

        ncfail = 0
        ncsuc = ncsuc + 1

        if ( 0.5D+00 <= ratio .or. 1 < ncsuc ) then
          delta = max ( delta, pnorm / 0.5D+00 )
        end if

        if ( abs ( ratio - 1.0D+00 ) <= 0.1D+00 ) then
          delta = pnorm / 0.5D+00
        end if

      end if
!
!  Successful iteration.
!  Update X, FVEC, and their norms.
!
      if ( 0.0001D+00 <= ratio ) then
        x3(1:n) = wa2(1:n)
        wa2(1:n) = diag(1:n) * x3(1:n)
        fvec(1:n) = wa4(1:n)
        xnorm = enorm ( n, wa2 )
        fnorm = fnorm1
        iter = iter + 1
      end if
!
!  Determine the progress of the iteration.
!
      nslow1 = nslow1 + 1
      if ( 0.001D+00 <= actred ) then
        nslow1 = 0
      end if

      if ( jeval ) then
        nslow2 = nslow2 + 1
      end if

      if ( 0.1D+00 <= actred ) then
        nslow2 = 0
      end if
!
!  Test for convergence.
!
      if ( delta <= xtol * xnorm .or. fnorm == 0.0D+00 ) then
        info = 1
      end if

      if ( info /= 0 ) then
        return
      end if
!
!  Tests for termination and stringent tolerances.
!
      if ( maxfev <= nfev ) then
        info = 2
      end if

      if ( 0.1D+00 * max ( 0.1D+00 * delta, pnorm ) <= epsmch * xnorm ) then
        info = 3
      end if

      if ( nslow2 == 5 ) then
        info = 4
      end if

      if ( nslow1 == 10 ) then
        info = 5
      end if

      if ( info /= 0 ) then
        return
      end if
!
!  Criterion for recalculating jacobian approximation
!  by forward differences.
!
      if ( ncfail == 2 ) then
        exit
      end if
!
!  Calculate the rank one modification to the jacobian
!  and update QTF if necessary.
!
      do j = 1, n
        sum2 = dot_product ( wa4(1:n), fjac(1:n,j) )
        wa2(j) = ( sum2 - wa3(j) ) / pnorm
        wa1(j) = diag(j) * ( ( diag(j) * wa1(j) ) / pnorm )
        if ( 0.0001D+00 <= ratio ) then
          qtf(j) = sum2
        end if
      end do
!
!  Compute the QR factorization of the updated jacobian.
!
      call r1updt ( n, n, r, lr, wa1, wa2, wa3, sing )
      call r1mpyq ( n, n, fjac, ldfjac, wa2, wa3 )
      call r1mpyq ( 1, n, qtf, 1, wa2, wa3 )
!
!  End of the inner loop.
!
      jeval = .false.

    end do
!
!  End of the outer loop.
!
  end do

  return
end
subroutine hybrd_be ( dydt, n, to, xo, t, x, fvec, xtol, maxfev, ml, mu, &
  epsfcn, diag, mode, factor, info, nfev, fjac, ldfjac, r, lr, qtf )

!*****************************************************************************80
!
!! hybrd_be() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  The user must provide a
!    subroutine which calculates the functions.  
!
!    The jacobian is then calculated by a forward-difference approximation.
!
!    The original code hybrd() was modified to deal with problems
!    involving a backward Euler residual.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    08 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(), the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(n)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(n)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) to, xo(n): the old time and solution.
!   
!    real ( kind = rk ) t, x(n): the new time and current solution estimate. 
!
!    real ( kind = rk ) xtol: Termination occurs when the relative error
!    between two consecutive iterates is at most XTOL.  XTOL should be
!    nonnegative.
!
!    integer maxfev: Termination occurs when the number of
!    calls to the derivative code is at least MAXFEV by the end of an iteration.
!
!    integer ml, mu: specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the jacobian
!    is not banded, set ML and MU to at least n - 1.
!
!    real ( kind = rk ) epsfcn: is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!    real ( kind = rk ) diag(n): multiplicative scale factors for the 
!    variables.  Only needed as input if MODE = 2.  
!
!    integer mode: scaling option.
!    1, variables will be scaled internally.
!    2, scaling is specified by the input DIAG vector.
!
!    real ( kind = rk ) factor: determines the initial step bound.  This
!    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
!    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
!    in the interval (0.1, 100) with 100 the recommended value.
!
!    integer ldfjac: the leading dimension of FJAC.
!    LDFJAC must be at least N.
!
!    integer lr: the size of the R array, which must be no
!    less than (N*(N+1))/2.
!
!  Output:
!
!    real ( kind = rk ) x(n): the final estimate of the solution vector.
!
!    real ( kind = rk ) fvec(n): the functions evaluated at the output x.
!
!    real ( kind = rk ) diag(n): multiplicative scale factors for the 
!    variables.  Set internally if MODE = 1.
!    
!    integer info: status flag.  A value of 1 indicates success. 
!    0, improper input parameters.
!    1, relative error between two consecutive iterates is at most XTOL.
!    2, number of calls to derivative has reached or exceeded MAXFEV.
!    3, XTOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, iteration is not making good progress, as measured by the improvement
!       from the last five jacobian evaluations.
!    5, iteration is not making good progress, as measured by the improvement
!       from the last ten iterations.
!
!    integer nfev: the number of calls to the derivative function.
!
!    real ( kind = rk ) fjac(ldfjac,n): an N by N array which contains
!    the orthogonal matrix Q produced by the QR factorization of the final
!    approximate jacobian.
!
!    real ( kind = rk ) r(lr): the upper triangular matrix produced by
!    the QR factorization of the final approximate jacobian, stored rowwise.
!
!    real ( kind = rk ) qtf(n): contains the vector Q'*FVEC.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer lr
  integer n

  real ( kind = rk ) actred
  real ( kind = rk ) delta
  real ( kind = rk ) diag(n)
  external dydt
  real ( kind = rk ) enorm
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) factor
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fnorm
  real ( kind = rk ) fnorm1
  real ( kind = rk ) fvec(n)
  integer i
  integer info
  integer iter
  integer iwa(1)
  integer j
  logical jeval
  integer l
  integer maxfev
  integer ml
  integer mode
  integer msum
  integer mu
  integer ncfail
  integer ncsuc
  integer nfev
  integer nslow1
  integer nslow2
  logical pivot
  real ( kind = rk ) pnorm
  real ( kind = rk ) prered
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r(lr)
  real ( kind = rk ) ratio
  logical sing
  real ( kind = rk ) sum2
  real ( kind = rk ) t
  real ( kind = rk ) temp
  real ( kind = rk ) to
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) wa3(n)
  real ( kind = rk ) wa4(n)
  real ( kind = rk ) x(n)
  real ( kind = rk ) xnorm
  real ( kind = rk ) xo(n)
  real ( kind = rk ) xtol

  epsmch = epsilon ( epsmch )

  info = 0
  nfev = 0
!
!  Check the input parameters for errors.
!
  if ( n <= 0 ) then
    return
  else if ( xtol < 0.0D+00 ) then
    return
  else if ( maxfev <= 0 ) then
    return
  else if ( ml < 0 ) then
    return
  else if ( mu < 0 ) then
    return
  else if ( factor <= 0.0D+00 ) then
    return
  else if ( ldfjac < n ) then
    return
  else if ( lr < ( n * ( n + 1 ) ) / 2 ) then
    return
  end if

  if ( mode == 2 ) then

    do j = 1, n
      if ( diag(j) <= 0.0D+00 ) then
        return
      end if
    end do

  end if
!
!  Evaluate the function at the starting point
!  and calculate its norm.
!
  call backward_euler_residual ( dydt, n, to, xo, t, x, fvec )
  nfev = 1

  fnorm = enorm ( n, fvec )
!
!  Determine the number of calls needed to compute the jacobian matrix.
!
  msum = min ( ml + mu + 1, n )
!
!  Initialize iteration counter and monitors.
!
  iter = 1
  ncsuc = 0
  ncfail = 0
  nslow1 = 0
  nslow2 = 0
!
!  Beginning of the outer loop.
!
  do

    jeval = .true.
!
!  Calculate the jacobian matrix.
!
    call fdjac_be ( dydt, n, to, xo, t, x, fvec, fjac, ldfjac, ml, mu, epsfcn )

    nfev = nfev + msum
!
!  Compute the QR factorization of the jacobian.
!
    pivot = .false.
    call qrfac ( n, n, fjac, ldfjac, pivot, iwa, 1, wa1, wa2 )
!
!  On the first iteration, if MODE is 1, scale according
!  to the norms of the columns of the initial jacobian.
!
    if ( iter == 1 ) then

      if ( mode /= 2 ) then

        diag(1:n) = wa2(1:n)
        do j = 1, n
          if ( wa2(j) == 0.0D+00 ) then
            diag(j) = 1.0D+00
          end if
        end do

      end if
!
!  On the first iteration, calculate the norm of the scaled X
!  and initialize the step bound DELTA.
!
      wa3(1:n) = diag(1:n) * x(1:n)
      xnorm = enorm ( n, wa3 )
      delta = factor * xnorm
      if ( delta == 0.0D+00 ) then
        delta = factor
      end if

    end if
!
!  Form Q' * FVEC and store in QTF.
!
    qtf(1:n) = fvec(1:n)

    do j = 1, n

      if ( fjac(j,j) /= 0.0D+00 ) then
        temp = - dot_product ( qtf(j:n), fjac(j:n,j) ) / fjac(j,j)
        qtf(j:n) = qtf(j:n) + fjac(j:n,j) * temp
      end if

    end do
!
!  Copy the triangular factor of the QR factorization into R.
!
    sing = .false.

    do j = 1, n
      l = j
      do i = 1, j - 1
        r(l) = fjac(i,j)
        l = l + n - i
      end do
      r(l) = wa1(j)
      if ( wa1(j) == 0.0D+00 ) then
        sing = .true.
      end if
    end do
!
!  Accumulate the orthogonal factor in FJAC.
!
    call qform ( n, n, fjac, ldfjac )
!
!  Rescale if necessary.
!
    if ( mode /= 2 ) then
      do j = 1, n
        diag(j) = max ( diag(j), wa2(j) )
      end do
    end if
!
!  Beginning of the inner loop.
!
    do
!
!  Determine the direction P.
!
      call dogleg ( n, r, lr, diag, qtf, delta, wa1 )
!
!  Store the direction P and X + P.
!  Calculate the norm of P.
!
      wa1(1:n) = - wa1(1:n)
      wa2(1:n) = x(1:n) + wa1(1:n)
      wa3(1:n) = diag(1:n) * wa1(1:n)

      pnorm = enorm ( n, wa3 )
!
!  On the first iteration, adjust the initial step bound.
!
      if ( iter == 1 ) then
        delta = min ( delta, pnorm )
      end if
!
!  Evaluate the function at X + P and calculate its norm.
!
      call backward_euler_residual ( dydt, n, to, xo, t, wa2, wa4 )
      nfev = nfev + 1
      fnorm1 = enorm ( n, wa4 )
!
!  Compute the scaled actual reduction.
!
      actred = -1.0D+00
      if ( fnorm1 < fnorm ) then
        actred = 1.0D+00 - ( fnorm1 / fnorm ) ** 2
      end if
!
!  Compute the scaled predicted reduction.
!
      l = 1
      do i = 1, n
        sum2 = 0.0D+00
        do j = i, n
          sum2 = sum2 + r(l) * wa1(j)
          l = l + 1
        end do
        wa3(i) = qtf(i) + sum2
      end do

      temp = enorm ( n, wa3 )
      prered = 0.0D+00
      if ( temp < fnorm ) then
        prered = 1.0D+00 - ( temp / fnorm ) ** 2
      end if
!
!  Compute the ratio of the actual to the predicted reduction.
!
      ratio = 0.0D+00
      if ( 0.0D+00 < prered ) then
        ratio = actred / prered
      end if
!
!  Update the step bound.
!
      if ( ratio < 0.1D+00 ) then

        ncsuc = 0
        ncfail = ncfail + 1
        delta = 0.5D+00 * delta

      else

        ncfail = 0
        ncsuc = ncsuc + 1

        if ( 0.5D+00 <= ratio .or. 1 < ncsuc ) then
          delta = max ( delta, pnorm / 0.5D+00 )
        end if

        if ( abs ( ratio - 1.0D+00 ) <= 0.1D+00 ) then
          delta = pnorm / 0.5D+00
        end if

      end if
!
!  Successful iteration.
!  Update X, FVEC, and their norms.
!
      if ( 0.0001D+00 <= ratio ) then
        x(1:n) = wa2(1:n)
        wa2(1:n) = diag(1:n) * x(1:n)
        fvec(1:n) = wa4(1:n)
        xnorm = enorm ( n, wa2 )
        fnorm = fnorm1
        iter = iter + 1
      end if
!
!  Determine the progress of the iteration.
!
      nslow1 = nslow1 + 1
      if ( 0.001D+00 <= actred ) then
        nslow1 = 0
      end if

      if ( jeval ) then
        nslow2 = nslow2 + 1
      end if

      if ( 0.1D+00 <= actred ) then
        nslow2 = 0
      end if
!
!  Test for convergence.
!
      if ( delta <= xtol * xnorm .or. fnorm == 0.0D+00 ) then
        info = 1
      end if

      if ( info /= 0 ) then
        return
      end if
!
!  Tests for termination and stringent tolerances.
!
      if ( maxfev <= nfev ) then
        info = 2
      end if

      if ( 0.1D+00 * max ( 0.1D+00 * delta, pnorm ) <= epsmch * xnorm ) then
        info = 3
      end if

      if ( nslow2 == 5 ) then
        info = 4
      end if

      if ( nslow1 == 10 ) then
        info = 5
      end if

      if ( info /= 0 ) then
        return
      end if
!
!  Criterion for recalculating jacobian approximation
!  by forward differences.
!
      if ( ncfail == 2 ) then
        exit
      end if
!
!  Calculate the rank one modification to the jacobian
!  and update QTF if necessary.
!
      do j = 1, n
        sum2 = dot_product ( wa4(1:n), fjac(1:n,j) )
        wa2(j) = ( sum2 - wa3(j) ) / pnorm
        wa1(j) = diag(j) * ( ( diag(j) * wa1(j) ) / pnorm )
        if ( 0.0001D+00 <= ratio ) then
          qtf(j) = sum2
        end if
      end do
!
!  Compute the QR factorization of the updated jacobian.
!
      call r1updt ( n, n, r, lr, wa1, wa2, wa3, sing )
      call r1mpyq ( n, n, fjac, ldfjac, wa2, wa3 )
      call r1mpyq ( 1, n, qtf, 1, wa2, wa3 )
!
!  End of the inner loop.
!
      jeval = .false.

    end do
!
!  End of the outer loop.
!
  end do

  return
end
subroutine hybrd_tr ( dydt, n, to, xo, tn, xn, fvec, xtol, maxfev, ml, mu, &
  epsfcn, diag, mode, factor, info, nfev, fjac, ldfjac, r, lr, qtf )

!*****************************************************************************80
!
!! hybrd_tr() seeks a zero of N nonlinear equations in N variables.
!
!  Discussion:
!
!    The code finds a zero of a system of N nonlinear functions in N variables
!    by a modification of the Powell hybrid method.  The user must provide a
!    subroutine which calculates the functions.  
!
!    The jacobian is then calculated by a forward-difference approximation.
!
!    The original code hybrd() was modified to deal with problems
!    involving an implicit trapezoidal ODE residual.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    15 November 2023
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Input:
!
!    external dydt(), the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(n)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(n)
!
!    integer n: the number of functions and variables.
!
!    real ( kind = rk ) to, xo(n): the old time and solution.
!   
!    real ( kind = rk ) tn, xn(n): the new time and current solution estimate. 
!
!    real ( kind = rk ) xtol: Termination occurs when the relative error
!    between two consecutive iterates is at most XTOL.  XTOL should be
!    nonnegative.
!
!    integer maxfev: Termination occurs when the number of
!    calls to the derivative code is at least MAXFEV by the end of an iteration.
!
!    integer ml, mu: specify the number of subdiagonals and
!    superdiagonals within the band of the jacobian matrix.  If the jacobian
!    is not banded, set ML and MU to at least n - 1.
!
!    real ( kind = rk ) epsfcn: is used in determining a suitable step
!    length for the forward-difference approximation.  This approximation
!    assumes that the relative errors in the functions are of the order of
!    EPSFCN.  If EPSFCN is less than the machine precision, it is assumed that
!    the relative errors in the functions are of the order of the machine
!    precision.
!
!    real ( kind = rk ) diag(n): multiplicative scale factors for the 
!    variables.  Only needed as input if MODE = 2.  
!
!    integer mode: scaling option.
!    1, variables will be scaled internally.
!    2, scaling is specified by the input DIAG vector.
!
!    real ( kind = rk ) factor: determines the initial step bound.  This
!    bound is set to the product of FACTOR and the euclidean norm of DIAG*X if
!    nonzero, or else to FACTOR itself.  In most cases, FACTOR should lie
!    in the interval (0.1, 100) with 100 the recommended value.
!
!    integer ldfjac: the leading dimension of FJAC.
!    LDFJAC must be at least N.
!
!    integer lr: the size of the R array, which must be no
!    less than (N*(N+1))/2.
!
!  Output:
!
!    real ( kind = rk ) xn(n): the final estimate of the solution vector.
!
!    real ( kind = rk ) fvec(n): the functions evaluated at the output xn.
!
!    real ( kind = rk ) diag(n): multiplicative scale factors for the 
!    variables.  Set internally if MODE = 1.
!    
!    integer info: status flag.  A value of 1 indicates success. 
!    0, improper input parameters.
!    1, relative error between two consecutive iterates is at most XTOL.
!    2, number of calls to derivative has reached or exceeded MAXFEV.
!    3, XTOL is too small.  No further improvement in the approximate
!       solution X is possible.
!    4, iteration is not making good progress, as measured by the improvement
!       from the last five jacobian evaluations.
!    5, iteration is not making good progress, as measured by the improvement
!       from the last ten iterations.
!
!    integer nfev: the number of calls to the derivative function.
!
!    real ( kind = rk ) fjac(ldfjac,n): an N by N array which contains
!    the orthogonal matrix Q produced by the QR factorization of the final
!    approximate jacobian.
!
!    real ( kind = rk ) r(lr): the upper triangular matrix produced by
!    the QR factorization of the final approximate jacobian, stored rowwise.
!
!    real ( kind = rk ) qtf(n): contains the vector Q'*FVEC.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldfjac
  integer lr
  integer n

  real ( kind = rk ) actred
  real ( kind = rk ) delta
  real ( kind = rk ) diag(n)
  external dydt
  real ( kind = rk ) enorm
  real ( kind = rk ) epsfcn
  real ( kind = rk ) epsmch
  real ( kind = rk ) factor
  real ( kind = rk ) fjac(ldfjac,n)
  real ( kind = rk ) fnorm
  real ( kind = rk ) fnorm1
  real ( kind = rk ) fvec(n)
  integer i
  integer info
  integer iter
  integer iwa(1)
  integer j
  logical jeval
  integer l
  integer maxfev
  integer ml
  integer mode
  integer msum
  integer mu
  integer ncfail
  integer ncsuc
  integer nfev
  integer nslow1
  integer nslow2
  logical pivot
  real ( kind = rk ) pnorm
  real ( kind = rk ) prered
  real ( kind = rk ) qtf(n)
  real ( kind = rk ) r(lr)
  real ( kind = rk ) ratio
  logical sing
  real ( kind = rk ) sum2
  real ( kind = rk ) temp
  real ( kind = rk ) tn
  real ( kind = rk ) to
  real ( kind = rk ) wa1(n)
  real ( kind = rk ) wa2(n)
  real ( kind = rk ) wa3(n)
  real ( kind = rk ) wa4(n)
  real ( kind = rk ) xn(n)
  real ( kind = rk ) xnorm
  real ( kind = rk ) xo(n)
  real ( kind = rk ) xtol

  epsmch = epsilon ( epsmch )

  info = 0
  nfev = 0
!
!  Check the input parameters for errors.
!
  if ( n <= 0 ) then
    return
  else if ( xtol < 0.0D+00 ) then
    return
  else if ( maxfev <= 0 ) then
    return
  else if ( ml < 0 ) then
    return
  else if ( mu < 0 ) then
    return
  else if ( factor <= 0.0D+00 ) then
    return
  else if ( ldfjac < n ) then
    return
  else if ( lr < ( n * ( n + 1 ) ) / 2 ) then
    return
  end if

  if ( mode == 2 ) then

    do j = 1, n
      if ( diag(j) <= 0.0D+00 ) then
        return
      end if
    end do

  end if
!
!  Evaluate the function at the starting point
!  and calculate its norm.
!
  call trapezoidal_residual ( dydt, n, to, xo, tn, xn, fvec )
  nfev = 1

  fnorm = enorm ( n, fvec )
!
!  Determine the number of calls needed to compute the jacobian matrix.
!
  msum = min ( ml + mu + 1, n )
!
!  Initialize iteration counter and monitors.
!
  iter = 1
  ncsuc = 0
  ncfail = 0
  nslow1 = 0
  nslow2 = 0
!
!  Beginning of the outer loop.
!
  do

    jeval = .true.
!
!  Calculate the jacobian matrix.
!
    call fdjac_tr ( dydt, n, to, xo, tn, xn, fvec, fjac, ldfjac, &
      ml, mu, epsfcn )

    nfev = nfev + msum
!
!  Compute the QR factorization of the jacobian.
!
    pivot = .false.
    call qrfac ( n, n, fjac, ldfjac, pivot, iwa, 1, wa1, wa2 )
!
!  On the first iteration, if MODE is 1, scale according
!  to the norms of the columns of the initial jacobian.
!
    if ( iter == 1 ) then

      if ( mode /= 2 ) then

        diag(1:n) = wa2(1:n)
        do j = 1, n
          if ( wa2(j) == 0.0D+00 ) then
            diag(j) = 1.0D+00
          end if
        end do

      end if
!
!  On the first iteration, calculate the norm of the scaled X
!  and initialize the step bound DELTA.
!
      wa3(1:n) = diag(1:n) * xn(1:n)
      xnorm = enorm ( n, wa3 )
      delta = factor * xnorm
      if ( delta == 0.0D+00 ) then
        delta = factor
      end if

    end if
!
!  Form Q' * FVEC and store in QTF.
!
    qtf(1:n) = fvec(1:n)

    do j = 1, n

      if ( fjac(j,j) /= 0.0D+00 ) then
        temp = - dot_product ( qtf(j:n), fjac(j:n,j) ) / fjac(j,j)
        qtf(j:n) = qtf(j:n) + fjac(j:n,j) * temp
      end if

    end do
!
!  Copy the triangular factor of the QR factorization into R.
!
    sing = .false.

    do j = 1, n
      l = j
      do i = 1, j - 1
        r(l) = fjac(i,j)
        l = l + n - i
      end do
      r(l) = wa1(j)
      if ( wa1(j) == 0.0D+00 ) then
        sing = .true.
      end if
    end do
!
!  Accumulate the orthogonal factor in FJAC.
!
    call qform ( n, n, fjac, ldfjac )
!
!  Rescale if necessary.
!
    if ( mode /= 2 ) then
      do j = 1, n
        diag(j) = max ( diag(j), wa2(j) )
      end do
    end if
!
!  Beginning of the inner loop.
!
    do
!
!  Determine the direction P.
!
      call dogleg ( n, r, lr, diag, qtf, delta, wa1 )
!
!  Store the direction P and X + P.
!  Calculate the norm of P.
!
      wa1(1:n) = - wa1(1:n)
      wa2(1:n) = xn(1:n) + wa1(1:n)
      wa3(1:n) = diag(1:n) * wa1(1:n)

      pnorm = enorm ( n, wa3 )
!
!  On the first iteration, adjust the initial step bound.
!
      if ( iter == 1 ) then
        delta = min ( delta, pnorm )
      end if
!
!  Evaluate the function at X + P and calculate its norm.
!
      call trapezoidal_residual ( dydt, n, to, xo, tn, wa2, wa4 )
      nfev = nfev + 1
      fnorm1 = enorm ( n, wa4 )
!
!  Compute the scaled actual reduction.
!
      actred = -1.0D+00
      if ( fnorm1 < fnorm ) then
        actred = 1.0D+00 - ( fnorm1 / fnorm ) ** 2
      end if
!
!  Compute the scaled predicted reduction.
!
      l = 1
      do i = 1, n
        sum2 = 0.0D+00
        do j = i, n
          sum2 = sum2 + r(l) * wa1(j)
          l = l + 1
        end do
        wa3(i) = qtf(i) + sum2
      end do

      temp = enorm ( n, wa3 )
      prered = 0.0D+00
      if ( temp < fnorm ) then
        prered = 1.0D+00 - ( temp / fnorm ) ** 2
      end if
!
!  Compute the ratio of the actual to the predicted reduction.
!
      ratio = 0.0D+00
      if ( 0.0D+00 < prered ) then
        ratio = actred / prered
      end if
!
!  Update the step bound.
!
      if ( ratio < 0.1D+00 ) then

        ncsuc = 0
        ncfail = ncfail + 1
        delta = 0.5D+00 * delta

      else

        ncfail = 0
        ncsuc = ncsuc + 1

        if ( 0.5D+00 <= ratio .or. 1 < ncsuc ) then
          delta = max ( delta, pnorm / 0.5D+00 )
        end if

        if ( abs ( ratio - 1.0D+00 ) <= 0.1D+00 ) then
          delta = pnorm / 0.5D+00
        end if

      end if
!
!  Successful iteration.
!  Update X, FVEC, and their norms.
!
      if ( 0.0001D+00 <= ratio ) then
        xn(1:n) = wa2(1:n)
        wa2(1:n) = diag(1:n) * xn(1:n)
        fvec(1:n) = wa4(1:n)
        xnorm = enorm ( n, wa2 )
        fnorm = fnorm1
        iter = iter + 1
      end if
!
!  Determine the progress of the iteration.
!
      nslow1 = nslow1 + 1
      if ( 0.001D+00 <= actred ) then
        nslow1 = 0
      end if

      if ( jeval ) then
        nslow2 = nslow2 + 1
      end if

      if ( 0.1D+00 <= actred ) then
        nslow2 = 0
      end if
!
!  Test for convergence.
!
      if ( delta <= xtol * xnorm .or. fnorm == 0.0D+00 ) then
        info = 1
      end if

      if ( info /= 0 ) then
        return
      end if
!
!  Tests for termination and stringent tolerances.
!
      if ( maxfev <= nfev ) then
        info = 2
      end if

      if ( 0.1D+00 * max ( 0.1D+00 * delta, pnorm ) <= epsmch * xnorm ) then
        info = 3
      end if

      if ( nslow2 == 5 ) then
        info = 4
      end if

      if ( nslow1 == 10 ) then
        info = 5
      end if

      if ( info /= 0 ) then
        return
      end if
!
!  Criterion for recalculating jacobian approximation
!  by forward differences.
!
      if ( ncfail == 2 ) then
        exit
      end if
!
!  Calculate the rank one modification to the jacobian
!  and update QTF if necessary.
!
      do j = 1, n
        sum2 = dot_product ( wa4(1:n), fjac(1:n,j) )
        wa2(j) = ( sum2 - wa3(j) ) / pnorm
        wa1(j) = diag(j) * ( ( diag(j) * wa1(j) ) / pnorm )
        if ( 0.0001D+00 <= ratio ) then
          qtf(j) = sum2
        end if
      end do
!
!  Compute the QR factorization of the updated jacobian.
!
      call r1updt ( n, n, r, lr, wa1, wa2, wa3, sing )
      call r1mpyq ( n, n, fjac, ldfjac, wa2, wa3 )
      call r1mpyq ( 1, n, qtf, 1, wa2, wa3 )
!
!  End of the inner loop.
!
      jeval = .false.

    end do
!
!  End of the outer loop.
!
  end do

  return
end
subroutine qform ( m, n, q, ldq )

!*****************************************************************************80
!
!! qform() produces the explicit QR factorization of a matrix.
!
!  Discussion:
!
!    The QR factorization of a matrix is usually accumulated in implicit
!    form, that is, as a series of orthogonal transformations of the
!    original matrix.  This routine carries out those transformations,
!    to explicitly exhibit the factorization constructed by QRFAC.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, integer M, is a positive integer input variable set
!    to the number of rows of A and the order of Q.
!
!    Input, integer N, is a positive integer input variable set
!    to the number of columns of A.
!
!    Input/output, real ( kind = rk ) Q(LDQ,M).  Q is an M by M array.
!    On input the full lower trapezoid in the first min(M,N) columns of Q
!    contains the factored form.
!    On output, Q has been accumulated into a square matrix.
!
!    Input, integer LDQ, is a positive integer input variable 
!    not less than M which specifies the leading dimension of the array Q.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ldq
  integer m
  integer n

  integer j
  integer k
  integer l
  integer minmn
  real ( kind = rk ) q(ldq,m)
  real ( kind = rk ) temp
  real ( kind = rk ) wa(m)

  minmn = min ( m, n )

  do j = 2, minmn
    q(1:j-1,j) = 0.0D+00
  end do
!
!  Initialize remaining columns to those of the identity matrix.
!
  q(1:m,n+1:m) = 0.0D+00

  do j = n + 1, m
    q(j,j) = 1.0D+00
  end do
!
!  Accumulate Q from its factored form.
!
  do l = 1, minmn

    k = minmn - l + 1

    wa(k:m) = q(k:m,k)

    q(k:m,k) = 0.0D+00
    q(k,k) = 1.0D+00

    if ( wa(k) /= 0.0D+00 ) then

      do j = k, m
        temp = dot_product ( wa(k:m), q(k:m,j) ) / wa(k)
        q(k:m,j) = q(k:m,j) - temp * wa(k:m)
      end do

    end if

  end do

  return
end
subroutine qrfac ( m, n, a, lda, pivot, ipvt, lipvt, rdiag, acnorm )

!*****************************************************************************80
!
!! qrfac() computes a QR factorization using Householder transformations.
!
!  Discussion:
!
!    This function uses Householder transformations with optional column
!    pivoting to compute a QR factorization of the
!    M by N matrix A.  That is, QRFAC determines an orthogonal
!    matrix Q, a permutation matrix P, and an upper trapezoidal
!    matrix R with diagonal elements of nonincreasing magnitude,
!    such that A*P = Q*R.  
!
!    The Householder transformation for column K, K = 1,2,...,min(M,N), 
!    is of the form
!
!      I - ( 1 / U(K) ) * U * U'
!
!    where U has zeros in the first K-1 positions.  
!
!    The form of this transformation and the method of pivoting first
!    appeared in the corresponding LINPACK routine.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, integer M, the number of rows of A.
!
!    Input, integer N, the number of columns of A.
!
!    Input/output, real ( kind = rk ) A(LDA,N), the M by N array.
!    On input, A contains the matrix for which the QR factorization is to
!    be computed.  On output, the strict upper trapezoidal part of A contains
!    the strict upper trapezoidal part of R, and the lower trapezoidal
!    part of A contains a factored form of Q, the non-trivial elements of
!    the U vectors described above.
!
!    Input, integer LDA, the leading dimension of A, which must
!    be no less than M.
!
!    Input, logical PIVOT, is TRUE if column pivoting is to be carried out.
!
!    Output, integer IPVT(LIPVT), defines the permutation matrix P 
!    such that A*P = Q*R.  Column J of P is column IPVT(J) of the identity 
!    matrix.  If PIVOT is false, IPVT is not referenced.
!
!    Input, integer LIPVT, the dimension of IPVT, which should 
!    be N if pivoting is used.
!
!    Output, real ( kind = rk ) RDIAG(N), contains the diagonal elements of R.
!
!    Output, real ( kind = rk ) ACNORM(N), the norms of the corresponding
!    columns of the input matrix A.  If this information is not needed,
!    then ACNORM can coincide with RDIAG.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer lda
  integer lipvt
  integer m
  integer n

  real ( kind = rk ) a(lda,n)
  real ( kind = rk ) acnorm(n)
  real ( kind = rk ) ajnorm
  real ( kind = rk ) enorm
  real ( kind = rk ) epsmch
  integer i4_temp
  integer ipvt(lipvt)
  integer j
  integer k
  integer kmax
  integer minmn
  logical pivot
  real ( kind = rk ) r8_temp(m)
  real ( kind = rk ) rdiag(n)
  real ( kind = rk ) temp
  real ( kind = rk ) wa(n)

  epsmch = epsilon ( epsmch )
!
!  Compute the initial column norms and initialize several arrays.
!
  do j = 1, n
    acnorm(j) = enorm ( m, a(1:m,j) )
  end do

  rdiag(1:n) = acnorm(1:n)
  wa(1:n) = acnorm(1:n)

  if ( pivot ) then
    do j = 1, n
      ipvt(j) = j
    end do
  end if
!
!  Reduce A to R with Householder transformations.
!
  minmn = min ( m, n )

  do j = 1, minmn
!
!  Bring the column of largest norm into the pivot position.
!
    if ( pivot ) then

      kmax = j

      do k = j, n
        if ( rdiag(kmax) < rdiag(k) ) then
          kmax = k
        end if
      end do

      if ( kmax /= j ) then

        r8_temp(1:m) = a(1:m,j)
        a(1:m,j)     = a(1:m,kmax)
        a(1:m,kmax)  = r8_temp(1:m)

        rdiag(kmax) = rdiag(j)
        wa(kmax) = wa(j)

        i4_temp    = ipvt(j)
        ipvt(j)    = ipvt(kmax)
        ipvt(kmax) = i4_temp

      end if

    end if
!
!  Compute the Householder transformation to reduce the
!  J-th column of A to a multiple of the J-th unit vector.
!
    ajnorm = enorm ( m-j+1, a(j,j) )

    if ( ajnorm /= 0.0D+00 ) then

      if ( a(j,j) < 0.0D+00 ) then
        ajnorm = -ajnorm
      end if

      a(j:m,j) = a(j:m,j) / ajnorm
      a(j,j) = a(j,j) + 1.0D+00
!
!  Apply the transformation to the remaining columns and update the norms.
!
      do k = j + 1, n

        temp = dot_product ( a(j:m,j), a(j:m,k) ) / a(j,j)

        a(j:m,k) = a(j:m,k) - temp * a(j:m,j)

        if ( pivot .and. rdiag(k) /= 0.0D+00 ) then

          temp = a(j,k) / rdiag(k)
          rdiag(k) = rdiag(k) * sqrt ( max ( 0.0D+00, 1.0D+00 - temp ** 2 ) )

          if ( 0.05D+00 * ( rdiag(k) / wa(k) ) ** 2 <= epsmch ) then
            rdiag(k) = enorm ( m-j, a(j+1,k) )
            wa(k) = rdiag(k)
          end if

        end if

      end do

    end if

    rdiag(j) = - ajnorm

  end do

  return
end
subroutine r1mpyq ( m, n, a, lda, v, w )

!*****************************************************************************80
!
!! r1mpyq() computes A*Q, where Q is the product of Householder transformations.
!
!  Discussion:
!
!    Given an M by N matrix A, this function computes A*Q where
!    Q is the product of 2*(N - 1) transformations
!
!      GV(N-1)*...*GV(1)*GW(1)*...*GW(N-1)
!
!    and GV(I), GW(I) are Givens rotations in the (I,N) plane which
!    eliminate elements in the I-th and N-th planes, respectively.
!    Q itself is not given, rather the information to recover the
!    GV, GW rotations is supplied.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, integer M, the number of rows of A.
!
!    Input, integer N, the number of columns of A.
!
!    Input/output, real ( kind = rk ) A(LDA,N), the M by N array.
!    On input, the matrix A to be postmultiplied by the orthogonal matrix Q.
!    On output, the value of A*Q.
!
!    Input, integer LDA, the leading dimension of A, which must not
!    be less than M.
!
!    Input, real ( kind = rk ) V(N), W(N), contain the information necessary
!    to recover the Givens rotations GV and GW.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer lda
  integer m
  integer n

  real ( kind = rk ) a(lda,n)
  real ( kind = rk ) c
  integer i
  integer j
  real ( kind = rk ) s
  real ( kind = rk ) temp
  real ( kind = rk ) v(n)
  real ( kind = rk ) w(n)
!
!  Apply the first set of Givens rotations to A.
!
  do j = n - 1, 1, -1

    if ( 1.0D+00 < abs ( v(j) ) ) then
      c = 1.0D+00 / v(j)
      s = sqrt ( 1.0D+00 - c ** 2 )
    else
      s = v(j)
      c = sqrt ( 1.0D+00 - s ** 2 )
    end if

    do i = 1, m
      temp =   c * a(i,j) - s * a(i,n)
      a(i,n) = s * a(i,j) + c * a(i,n)
      a(i,j) = temp
    end do

  end do
!
!  Apply the second set of Givens rotations to A.
!
  do j = 1, n - 1

    if ( 1.0D+00 < abs ( w(j) ) ) then
      c = 1.0D+00 / w(j)
      s = sqrt ( 1.0D+00 - c ** 2 )
    else
      s = w(j)
      c = sqrt ( 1.0D+00 - s ** 2 )
    end if

    do i = 1, m
      temp =     c * a(i,j) + s * a(i,n)
      a(i,n) = - s * a(i,j) + c * a(i,n)
      a(i,j) = temp
    end do

  end do

  return
end
subroutine r1updt ( m, n, s, ls, u, v, w, sing )

!*****************************************************************************80
!
!! r1updt() re-triangularizes a matrix after a rank one update.
!
!  Discussion:
!
!    Given an M by N lower trapezoidal matrix S, an M-vector U, and an
!    N-vector V, the problem is to determine an orthogonal matrix Q such that
!
!      (S + U * V' ) * Q
!
!    is again lower trapezoidal.
!
!    This function determines Q as the product of 2 * (N - 1)
!    transformations
!
!      GV(N-1)*...*GV(1)*GW(1)*...*GW(N-1)
!
!    where GV(I), GW(I) are Givens rotations in the (I,N) plane
!    which eliminate elements in the I-th and N-th planes,
!    respectively.  Q itself is not accumulated, rather the
!    information to recover the GV and GW rotations is returned.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    06 April 2010
!
!  Author:
!
!    Original FORTRAN77 version by Jorge More, Burton Garbow, Kenneth Hillstrom.
!    This version by John Burkardt.
!
!  Reference:
!
!    Jorge More, Burton Garbow, Kenneth Hillstrom,
!    User Guide for MINPACK-1,
!    Technical Report ANL-80-74,
!    Argonne National Laboratory, 1980.
!
!  Parameters:
!
!    Input, integer M, the number of rows of S.
!
!    Input, integer N, the number of columns of S.  
!    N must not exceed M.
!
!    Input/output, real ( kind = rk ) S(LS).  On input, the lower trapezoidal
!    matrix S stored by columns.  On output S contains the lower trapezoidal
!    matrix produced as described above.
!
!    Input, integer LS, the length of the S array.  LS must be at
!    least (N*(2*M-N+1))/2.
!
!    Input, real ( kind = rk ) U(M), the U vector.
!
!    Input/output, real ( kind = rk ) V(N).  On input, V must contain the 
!    vector V.  On output V contains the information necessary to recover the
!    Givens rotations GV described above.
!
!    Output, real ( kind = rk ) W(M), contains information necessary to
!    recover the Givens rotations GW described above.
!
!    Output, logical SING, is set to TRUE if any of the diagonal elements
!    of the output S are zero.  Otherwise SING is set FALSE.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer ls
  integer m
  integer n

  real ( kind = rk ) cos
  real ( kind = rk ) cotan
  real ( kind = rk ) giant
  integer i
  integer j
  integer jj
  integer l
  real ( kind = rk ) s(ls)
  real ( kind = rk ) sin
  logical sing
  real ( kind = rk ) tan
  real ( kind = rk ) tau
  real ( kind = rk ) temp
  real ( kind = rk ) u(m)
  real ( kind = rk ) v(n)
  real ( kind = rk ) w(m)
!
!  GIANT is the largest magnitude.
!
  giant = huge ( giant )
!
!  Initialize the diagonal element pointer.
!
  jj = ( n * ( 2 * m - n + 1 ) ) / 2 - ( m - n )
!
!  Move the nontrivial part of the last column of S into W.
!
  l = jj
  do i = n, m
    w(i) = s(l)
    l = l + 1
  end do
!
!  Rotate the vector V into a multiple of the N-th unit vector
!  in such a way that a spike is introduced into W.
!
  do j = n - 1, 1, -1

    jj = jj - ( m - j + 1 )
    w(j) = 0.0D+00

    if ( v(j) /= 0.0D+00 ) then
!
!  Determine a Givens rotation which eliminates the J-th element of V.
!
      if ( abs ( v(n) ) < abs ( v(j) ) ) then
        cotan = v(n) / v(j)
        sin = 0.5D+00 / sqrt ( 0.25D+00 + 0.25D+00 * cotan ** 2 )
        cos = sin * cotan
        tau = 1.0D+00
        if ( abs ( cos ) * giant > 1.0D+00 ) then
          tau = 1.0D+00 / cos
        end if
      else
        tan = v(j) / v(n)
        cos = 0.5D+00 / sqrt ( 0.25D+00 + 0.25D+00 * tan ** 2 )
        sin = cos * tan
        tau = sin
      end if
!
!  Apply the transformation to V and store the information
!  necessary to recover the Givens rotation.
!
      v(n) = sin * v(j) + cos * v(n)
      v(j) = tau
!
!  Apply the transformation to S and extend the spike in W.
!
      l = jj
      do i = j, m
        temp = cos * s(l) - sin * w(i)
        w(i) = sin * s(l) + cos * w(i)
        s(l) = temp
        l = l + 1
      end do

    end if

  end do
!
!  Add the spike from the rank 1 update to W.
!
   w(1:m) = w(1:m) + v(n) * u(1:m)
!
!  Eliminate the spike.
!
  sing = .false.

  do j = 1, n-1

    if ( w(j) /= 0.0D+00 ) then
!
!  Determine a Givens rotation which eliminates the
!  J-th element of the spike.
!
      if ( abs ( s(jj) ) < abs ( w(j) ) ) then

        cotan = s(jj) / w(j)
        sin = 0.5D+00 / sqrt ( 0.25D+00 + 0.25D+00 * cotan ** 2 )
        cos = sin * cotan

        if ( 1.0D+00 < abs ( cos ) * giant ) then
          tau = 1.0D+00 / cos
        else
          tau = 1.0D+00
        end if

      else

        tan = w(j) / s(jj)
        cos = 0.5D+00 / sqrt ( 0.25D+00 + 0.25D+00 * tan ** 2 )
        sin = cos * tan
        tau = sin

      end if
!
!  Apply the transformation to S and reduce the spike in W.
!
      l = jj
      do i = j, m
        temp = cos * s(l) + sin * w(i)
        w(i) = - sin * s(l) + cos * w(i)
        s(l) = temp
        l = l + 1
      end do
!
!  Store the information necessary to recover the Givens rotation.
!
      w(j) = tau

    end if
!
!  Test for zero diagonal elements in the output S.
!
    if ( s(jj) == 0.0D+00 ) then
      sing = .true.
    end if

    jj = jj + ( m - j + 1 )

  end do
!
!  Move W back into the last column of the output S.
!
  l = jj
  do i = n, m
    s(l) = w(i)
    l = l + 1
  end do

  if ( s(jj) == 0.0D+00 ) then
    sing = .true.
  end if

  return
end
 subroutine trapezoidal_residual ( dydt, n, to, yo, tn, yn, ft )

!*****************************************************************************80
!
!! trapezoidal_residual() evaluates the trapezoidal ODE solver residual.
!
!  Discussion:
!
!    Let to and tn be two times, with yo and yn the associated ODE
!    solution values there.  If yn satisfies the implicit trapezoidal
!    ODE solver condiion, then:
!
!      0.5 * ( dydt(to,yo) + dydt(tn,yn) ) = ( yn - yo ) / ( tn - to )
!
!    This can be rewritten as
!
!      residual = yn - yo - 0.5 * ( tn - to ) * ( dydt(to,yo) + dydt(tn,yn) )
!
!    Given the other information as fixed values, a nonlinear equation 
!    solver can be used to estimate the value yn that makes the residual zero.
!
!  Licensing:
!
!    This code is distributed under the MIT license.
!
!  Modified:
!
!    15 November 2023
!
!  Author:
!
!    John Burkardt
!
!  Input:
!
!    external dydt(): the name of the user-supplied code which
!    evaluates the right hand side of the ODE, of the form:
!      subroutine dydt ( t, y, dy )
!      real ( kind = rk ) dy(*)
!      real ( kind = rk ) t
!      real ( kind = rk ) y(*)
!
!    integer n: the vector size.
!
!    real ( kind = rk ) to, yo(n): the old time and solution.
!
!    real ( kind = rk ) tn, yn(n): the new time and tentative solution.
!
!  Output:
!
!    real ( kind = rk ) ft(n): the trapezoidal residual.
!
  implicit none

  integer, parameter :: rk = kind ( 1.0D+00 )

  integer n

  real ( kind = rk ) dydtn(n)
  real ( kind = rk ) dydto(n)
  external dydt
  real ( kind = rk ) ft(n)
  real ( kind = rk ) tn
  real ( kind = rk ) to
  real ( kind = rk ) yn(n)
  real ( kind = rk ) yo(n)

  call dydt ( to, yo, dydto )

  call dydt ( tn, yn, dydtn )

  ft = yn - yo - 0.5 * ( tn - to ) * ( dydto + dydtn )

  return
end

