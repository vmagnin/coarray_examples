!------------------------------------------------------------------------------
! Contributed by Vincent Magnin, 2026-04-25
! Last modification: vmagnin 2026-04-27
! MIT license
! https://en.wikipedia.org/wiki/Buddhabrot
!------------------------------------------------------------------------------

program ppm_coarray_buddhabrot
  use iso_fortran_env, only: int16, int32, int64, wp=>real64

  implicit none
  integer        :: u           ! File unit
  integer(int16), parameter :: pixwidth  = 1000
  integer(int16), parameter :: pixheight = 1000
  integer(int32) :: ii, jj      ! Pixel coordinates
  integer(int16) :: grey        ! Intensity of a pixel
  integer(int64) :: i           ! Main loop counter
  integer(int64) :: num_samples ! Number of c points explored by each image
  integer(int32) :: k           ! Loop counter for the Mandelbrot sequence
  integer(int32), parameter :: iterations = 200   ! Maximum iterations
  complex(wp), dimension(0:iterations) :: z       ! To memorize the sequence
  real(wp)       :: rx, ry      ! Random numbers
  complex(wp)    :: c           ! A point in the complex plane
  real(wp)       :: xmin, xmax, ymin, ymax
  ! Array to count the visits of each pixel by the mathematical sequence:
  integer(int32), dimension(0:pixwidth-1, 0:pixheight-1) :: p
  ! Maximum in the array:
  real(wp)            :: highest
  ! Multiplication factor used in the grey level computation:
  real(wp), parameter :: factor = 3._wp

  p = 0

  ! We share the work among all images:
  num_samples = 1250000000 / num_images()

  call random_init(repeatable=.true., image_distinct=.true.)

  ! The computing window is -2 < x < +1 ; -1.5 < y < +1.5
  ! (this square contains the whole Mandelbrot set)
  xmin = -2._wp
  xmax = +1._wp
  ymin = -1.5_wp
  ymax = +1.5_wp

  computation: do i = 1, num_samples
    ! Starting from a random point c in the complex plane:
    call random_number(rx)
    call random_number(ry)
    c = cmplx(xmin + (xmax-xmin) * rx, ymin + (ymax-ymin) * ry, kind=wp)

    ! Iterations of the Mandelbrot mathematical sequence:
    z(0) = (0._wp, 0._wp)    ! First term z0=0
    do k = 1, iterations
      z(k) = z(k-1)**2 + c
    end do

    ! We consider only sequences starting from points not in the Mandelbrot set
    ! (and therefore diverging):
    if (real(z(iterations))**2 + aimag(z(iterations))**2 >= 4._wp) then
      do k = 2, iterations
        ! Converting mathematical coordinates to pixel coordinates (ii,jj):
        ii = nint((real(z(k)) - xmin) / ((xmax-xmin) / pixwidth))

        ! Is (ii, jj) inside the picture?
        if ((ii >= 0) .and. (ii < pixwidth)) then
          jj = nint((aimag(z(k)) - ymin) / ((ymax-ymin) / pixheight))

          if ((jj >= 0) .and. (jj < pixheight)) then
            ! This pixel has been visited by z:
            p(ii,jj) = p(ii,jj) + 1
            ! The intensity of a pixel is proportional to the number of times
            ! it was visited.
          end if
        end if
      end do
    end if

    ! Printing the percentage of work done:
    if ((this_image() == 1) .and. (mod(i, num_samples/100) == 0)) then
      write(*, '(i3, "%")') i / (num_samples/100)
    end if
  end do computation

  ! Like in astrophotography, we sum the pictures computed by each
  ! Fortran image to obtain a detailed picture of the Buddhabrot:
  sync all
  print '(A, I3, A)', "I am image", this_image(), " doing co_sum(p, 1)"
  call co_sum(p, 1)

  if (this_image() == 1) then
    write(*,'(A)') "I am image 1 saving the picture in 'buddhabrot.ppm'"
    ! Based on Ondrej Certik's code (MIT license):
    ! https://github.com/certik/fortran-utils/blob/master/src/ppm.f90
    open(newunit=u, file="buddhabrot.ppm", status="replace")
    ! Header:
    write(u, '(a2)') "P6"
    write(u, '(i0," ",i0)') pixwidth, pixheight
    write(u, '(i0)') 255    ! maximum value for each RGB color
    highest = real(maxval(p), kind=wp)
    ! Data (note that the Buddha is sitting! x is therefore the vertical axis):
    do ii = 0, pixwidth-1
      do jj = pixheight-1, 0, -1
        grey = min(255, nint((255*factor*p(ii,jj)) / highest, kind=int16))
        write(u, '(3a1)', advance='no') achar(grey), achar(grey), achar(grey)
      end do
    end do

    close(u)
  end if

end program ppm_coarray_buddhabrot
