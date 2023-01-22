c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1990  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ###############################################################
c     ##                                                           ##
c     ##  program newton  --  perform TNCG Cartesian optimization  ##
c     ##                                                           ##
c     ###############################################################
c
c
c     "newton" performs an energy minimization in Cartesian
c     coordinate space using a truncated Newton method
c
c
      program newton
      use atoms
      use bound
      use files
      use inform
      use iounit
      use usage
      implicit none
      integer i,j,k,next
      integer imin,nvar
      integer freeunit
      real*8 gnorm,grms,grdmin
      real*8 minimum,newton1
      real*8, allocatable :: xx(:)
      real*8, allocatable :: derivs(:,:)
      logical exist
      character*1 answer
      character*6 mode,method
      character*240 minfile
      character*240 record
      character*240 string
      external newton1
      external newton2
      external optsave
c
c
c     set up the structure and mechanics calculation
c
      call initial
      call getxyz
      call mechanic
c
c     perform the setup functions needed for optimization
c
      call optinit
c
c     get the type of optimization algorithm to use
c
      mode = 'AUTO'
      call nextarg (answer,exist)
      if (.not. exist) then
         answer = 'A'
         write (iout,10)  answer
   10    format (/,' Choose Automatic, Newton, TNCG or DTNCG',
     &              ' Method [',a1,'] :  ',$)
         read (input,20)  record
   20    format (a240)
         next = 1
         call gettext (record,answer,next)
      end if
      call upcase (answer)
      if (answer .eq. 'A')  mode = 'AUTO'
      if (answer .eq. 'N')  mode = 'NEWTON'
      if (answer .eq. 'T')  mode = 'TNCG'
      if (answer .eq. 'D')  mode = 'DTNCG'
c
c     get the type of linear equation preconditioning to use
c
      method = 'AUTO'
      call nextarg (answer,exist)
      if (.not. exist) then
         answer = 'A'
         write (iout,30)  answer
   30    format (/,' Precondition via Auto/None/Diag/Block/',
     &              'SSOR/ICCG [',a1,'] :  ',$)
         read (input,40)  record
   40    format (a240)
         next = 1
         call gettext (record,answer,next)
      end if
      call upcase (answer)
      if (answer .eq. 'A')  method = 'AUTO'
      if (answer .eq. 'N')  method = 'NONE'
      if (answer .eq. 'D')  method = 'DIAG'
      if (answer .eq. 'B')  method = 'BLOCK'
      if (answer .eq. 'S')  method = 'SSOR'
      if (answer .eq. 'I')  method = 'ICCG'
c
c     get the termination criterion as RMS gradient per atom
c
      grdmin = -1.0d0
      call nextarg (string,exist)
      if (exist)  read (string,*,err=50,end=50)  grdmin
   50 continue
      if (grdmin .le. 0.0d0) then
         write (iout,60)
   60    format (/,' Enter RMS Gradient per Atom Criterion',
     &              ' [0.01] :  ',$)
         read (input,70)  grdmin
   70    format (f20.0)
      end if
      if (grdmin .le. 0.0d0)  grdmin = 0.01d0
c
c     write out a copy of coordinates for later update
c
      imin = freeunit ()
      minfile = basename(1:leng)//'.xyz'
      call version (minfile,'new')
      open (unit=imin,file=minfile,status='new')
      call prtxyz (imin)
      close (unit=imin)
      outfile = minfile
c
c     perform dynamic allocation of some local arrays
c
      allocate (xx(3*n))
      allocate (derivs(3,n))
c
c     convert atomic coordinates to optimization parameters
c
      nvar = 0
      do i = 1, nuse
         k = iuse(i)
         nvar = nvar + 1
         xx(nvar) = x(k)
         nvar = nvar + 1
         xx(nvar) = y(k)
         nvar = nvar + 1
         xx(nvar) = z(k)
      end do
c
c     make the call to the optimization routine
c
      call tncg (mode,method,nvar,xx,minimum,grdmin,
     &               newton1,newton2,optsave)
c
c     convert optimization parameters to atomic coordinates
c
      nvar = 0
      do i = 1, nuse
         k = iuse(i)
         nvar = nvar + 1
         x(k) = xx(nvar)
         nvar = nvar + 1
         y(k) = xx(nvar)
         nvar = nvar + 1
         z(k) = xx(nvar)
      end do
c
c     compute the final function and RMS gradient values
c
      call gradient (minimum,derivs)
      gnorm = 0.0d0
      do i = 1, nuse
         k = iuse(i)
         do j = 1, 3
            gnorm = gnorm + derivs(j,k)**2
         end do
      end do
      gnorm = sqrt(gnorm)
      grms = gnorm / sqrt(dble(nvar/3))
c
c     perform deallocation of some local arrays
c
      deallocate (xx)
      deallocate (derivs)
c
c     write out the final function and gradient values
c
      if (digits .ge. 8) then
         if (grms .gt. 1.0d-8) then
            write (iout,80)  minimum,grms,gnorm
   80       format (/,' Final Function Value :',2x,f20.8,
     &              /,' Final RMS Gradient :',4x,f20.8,
     &              /,' Final Gradient Norm :',3x,f20.8)
         else
            write (iout,90)  minimum,grms,gnorm
   90       format (/,' Final Function Value :',2x,f20.8,
     &              /,' Final RMS Gradient :',4x,d20.8,
     &              /,' Final Gradient Norm :',3x,d20.8)
         end if
      else if (digits .ge. 6) then
         if (grms .gt. 1.0d-6) then
            write (iout,100)  minimum,grms,gnorm
  100       format (/,' Final Function Value :',2x,f18.6,
     &              /,' Final RMS Gradient :',4x,f18.6,
     &              /,' Final Gradient Norm :',3x,f18.6)
         else
            write (iout,110)  minimum,grms,gnorm
  110       format (/,' Final Function Value :',2x,f18.6,
     &              /,' Final RMS Gradient :',4x,d18.6,
     &              /,' Final Gradient Norm :',3x,d18.6)
         end if
      else
         if (grms .gt. 1.0d-4) then
            write (iout,120)  minimum,grms,gnorm
  120       format (/,' Final Function Value :',2x,f16.4,
     &              /,' Final RMS Gradient :',4x,f16.4,
     &              /,' Final Gradient Norm :',3x,f16.4)
         else
            write (iout,130)  minimum,grms,gnorm
  130       format (/,' Final Function Value :',2x,f16.4,
     &              /,' Final RMS Gradient :',4x,d16.4,
     &              /,' Final Gradient Norm :',3x,d16.4)
         end if
      end if
c
c     move stray molecules into periodic box if desired
c
c     if (use_bounds)  call bounds
c
c     write the final coordinates into a file
c
      imin = freeunit ()
      open (unit=imin,file=minfile,status='old')
      rewind (unit=imin)
      call prtxyz (imin)
      close (unit=imin)
c
c     perform any final tasks before program exit
c
      call final
      end
c
c
c     ############################################################
c     ##                                                        ##
c     ##  function newton1  --  energy and gradient for newton  ##
c     ##                                                        ##
c     ############################################################
c
c
c     "newton1" is a service routine that computes the energy
c     and gradient for truncated Newton optimization in Cartesian
c     coordinate space
c
c
      function newton1 (xx,g)
      use atoms
      use usage
      implicit none
      integer i,k,nvar
      real*8 newton1,e
      real*8 xx(*)
      real*8 g(*)
      real*8, allocatable :: derivs(:,:)
c
c
c     convert optimization parameters to atomic coordinates
c
      nvar = 0
      do i = 1, nuse
         k = iuse(i)
         nvar = nvar + 1
         x(k) = xx(nvar)
         nvar = nvar + 1
         y(k) = xx(nvar)
         nvar = nvar + 1
         z(k) = xx(nvar)
      end do
c
c     perform dynamic allocation of some local arrays
c
      allocate (derivs(3,n))
c
c     compute and store the energy and gradient
c
      call gradient (e,derivs)
      newton1 = e
c
c     convert gradient components to optimization parameters
c
      nvar = 0
      do i = 1, nuse
         k = iuse(i)
         nvar = nvar + 1
         g(nvar) = derivs(1,k)
         nvar = nvar + 1
         g(nvar) = derivs(2,k)
         nvar = nvar + 1
         g(nvar) = derivs(3,k)
      end do
c
c     perform deallocation of some local arrays
c
      deallocate (derivs)
      return
      end
c
c
c     #########################################################
c     ##                                                     ##
c     ##  subroutine newton2  --  Hessian values for newton  ##
c     ##                                                     ##
c     #########################################################
c
c
c     "newton2" is a service routine that computes the sparse
c     matrix Hessian elements for truncated Newton optimization
c     in Cartesian coordinate space
c
c
      subroutine newton2 (mode,xx,h,hinit,hstop,hindex,hdiag)
      use atoms
      use usage
      implicit none
      integer i,j,k,nvar
      integer hinit(*)
      integer hstop(*)
      integer hindex(*)
      integer, allocatable :: hvar(:)
      integer, allocatable :: huse(:)
      real*8 xx(*)
      real*8 hdiag(*)
      real*8 h(*)
      character*4 mode
c
c
c     convert optimization parameters to atomic coordinates
c
      if (mode .eq. 'NONE')  return
      nvar = 0
      do i = 1, n
         k = iuse(i)
         nvar = nvar + 1
         x(k) = xx(nvar)
         nvar = nvar + 1
         y(k) = xx(nvar)
         nvar = nvar + 1
         z(k) = xx(nvar)
      end do
c
c     compute and store the Hessian elements
c
      call hessian (h,hinit,hstop,hindex,hdiag)
c
c     perform dynamic allocation of some local arrays
c
      allocate (hvar(nvar))
      allocate (huse(3*n))
c
c     transform the sparse Hessian to use only active atoms
c
      nvar = 0
      if (nuse .ne. n) then
         do i = 1, n
            k = 3 * (i-1)
            if (use(i)) then
               do j = 1, 3
                  nvar = nvar + 1
                  hvar(nvar) = j + k
                  huse(j+k) = nvar
               end do
            else
               do j = 1, 3
                  huse(j+k) = 0
               end do
            end if
         end do
         do i = 1, nvar
            k = hvar(i)
            hinit(i) = hinit(k)
            hstop(i) = hstop(k)
            hdiag(i) = hdiag(k)
            do j = hinit(i), hstop(i)
               hindex(j) = huse(hindex(j))
            end do
         end do
      end if
c
c     convert atomic coordinates to optimization parameters
c
      nvar = 0
      do i = 1, nuse
         k = iuse(i)
         nvar = nvar + 1
         xx(nvar) = x(k)
         nvar = nvar + 1
         xx(nvar) = y(k)
         nvar = nvar + 1
         xx(nvar) = z(k)
      end do
c
c     perform deallocation of some local arrays
c
      deallocate (hvar)
      deallocate (huse)
      return
      end
