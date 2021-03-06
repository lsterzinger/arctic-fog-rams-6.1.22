!
! Copyright (C) 1991-2004  ; All Rights Reserved ; Colorado State University
! Colorado State University Research Foundation ; ATMET, LLC
! 
! This file is free software; you can redistribute it and/or modify it under the
! terms of the GNU General Public License as published by the Free Software 
! Foundation; either version 2 of the License, or (at your option) any later version.
! 
! This software is distributed in the hope that it will be useful, but WITHOUT ANY 
! WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE.  See the GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along with this 
! code; if not, write to the Free Software Foundation, Inc., 
! 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
!======================================================================================

Subroutine thermo (mzp,mxp,myp,ia,iz,ja,jz)

use mem_grid
use mem_basic
use mem_micro
use mem_scratch
use micphys

implicit none

integer :: mzp,mxp,myp,ia,iz,ja,jz

if (level .le. 1) then

   CALL drythrm (mzp,mxp,myp,ia,iz,ja,jz  &
      ,basic_g(ngrid)%thp(1,1,1) ,basic_g(ngrid)%theta(1,1,1)   &
      ,basic_g(ngrid)%rtp(1,1,1) ,basic_g(ngrid)%rv(1,1,1),level)

elseif (level .eq. 2) then

   CALL satadjst (mzp,mxp,myp,ia,iz,ja,jz  &
      ,basic_g(ngrid)%pp(1,1,1)  ,scratch%scr1(1)             &
      ,basic_g(ngrid)%thp(1,1,1) ,basic_g(ngrid)%theta(1,1,1) &
      ,scratch%vt3db(1)          ,basic_g(ngrid)%pi0(1,1,1)   &
      ,basic_g(ngrid)%rtp(1,1,1) ,basic_g(ngrid)%rv(1,1,1)    &
      ,micro_g(ngrid)%rcp(1,1,1) ,scratch%scr2(1))

elseif (level .eq. 3) then

   CALL wetthrm3 (mzp,mxp,myp,ia,iz,ja,jz,jnmb  &
     ,basic_g(ngrid)%pi0(1,1,1) ,basic_g(ngrid)%pp   (1,1,1)  &
     ,basic_g(ngrid)%thp(1,1,1) ,basic_g(ngrid)%theta(1,1,1)  &
     ,basic_g(ngrid)%rtp(1,1,1) ,basic_g(ngrid)%rv   (1,1,1)  &
     ,micro_g(ngrid)%rcp(1,1,1) ,micro_g(ngrid)%rrp  (1,1,1)  &
     ,micro_g(ngrid)%rpp(1,1,1) ,micro_g(ngrid)%rsp  (1,1,1)  &
     ,micro_g(ngrid)%rap(1,1,1) ,micro_g(ngrid)%rgp  (1,1,1)  &
     ,micro_g(ngrid)%rhp(1,1,1) ,micro_g(ngrid)%q6   (1,1,1)  &
     ,micro_g(ngrid)%q7(1,1,1)  ,micro_g(ngrid)%rdp  (1,1,1)  &
     ,vctr1,vctr2,vctr3,vctr4,vctr5,vctr6)

else

   stop 'Thermo option not supported...LEVEL out of bounds'

endif

return
END SUBROUTINE thermo

!##############################################################################
Subroutine drythrm (m1,m2,m3,ia,iz,ja,jz,thil,theta,rt,rv,level)

! This routine calculates theta and rv for the case where no condensate is
! allowed.

implicit none

integer m1,m2,m3,ia,iz,ja,jz,i,j,k,level
real thil(m1,m2,m3),theta(m1,m2,m3),rt(m1,m2,m3),rv(m1,m2,m3)

do j = ja,jz
   do i = ia,iz
      do k = 1,m1
         theta(k,i,j) = thil(k,i,j)
      enddo
      if (level .eq. 1) then
         do k = 1,m1
            rv(k,i,j) = rt(k,i,j)
         enddo
      endif
   enddo
enddo

return
END SUBROUTINE drythrm

!##############################################################################
Subroutine satadjst (m1,m2,m3,ia,iz,ja,jz  &
   ,pp,p,thil,theta,t,pi0,rtp,rv,rcp,rvls)

! This routine diagnoses theta, rv, and rcp using a saturation adjustment
! for the case when water is in the liquid phase only

use rconstants

implicit none

integer :: m1,m2,m3,ia,iz,ja,jz
real :: pp(m1,m2,m3),p(m1,m2,m3),thil(m1,m2,m3),theta(m1,m2,m3)  &
   ,t(m1,m2,m3),pi0(m1,m2,m3),rtp(m1,m2,m3),rv(m1,m2,m3)  &
   ,rcp(m1,m2,m3),rvls(m1,m2,m3)
real, external :: rslf
integer :: i,j,k,iterate
real :: picpi,til,tt

do j = ja,jz
   do i = ia,iz
      do k = 1,m1
         picpi = (pi0(k,i,j) + pp(k,i,j)) * cpi
         p(k,i,j) = p00 * picpi ** 3.498
         til = thil(k,i,j) * picpi
         t(k,i,j) = til

         do iterate = 1,20
            rvls(k,i,j) = rslf(p(k,i,j),t(k,i,j))
            rcp(k,i,j) = max(rtp(k,i,j) - rvls(k,i,j),0.)
            tt = 0.7 * t(k,i,j) + 0.3 * til  &
               * (1. + alvl * rcp(k,i,j)  &
               / (cp * max(t(k,i,j),253.)))
            if (abs(tt - t(k,i,j)) .le. 0.001) go to 1
            t(k,i,j) = tt
         enddo
1             continue
         rv(k,i,j) = rtp(k,i,j) - rcp(k,i,j)
         theta(k,i,j) = t(k,i,j) / picpi
      enddo
   enddo
enddo

return
END SUBROUTINE satadjst

!##############################################################################
Subroutine wetthrm3 (m1,m2,m3,ia,iz,ja,jz,jnmb  &
   ,pi0,pp,thp,theta,rtp,rv,rcp,rrp,rpp,rsp,rap,rgp,rhp,q6,q7,rdp  &
   ,picpi,tair,til,rliq,rice,qhydm)

! This routine calculates theta and rv for "level 3 microphysics"
! given prognosed theta_il, cloud, rain, pristine ice, snow, aggregates,
! graupel, hail, q6, and q7.

use rconstants

implicit none

integer :: m1,m2,m3,ia,iz,ja,jz,jnmb(*)
real :: pi0(m1,m2,m3),pp(m1,m2,m3),thp(m1,m2,m3),theta(m1,m2,m3)  &
   ,rtp(m1,m2,m3),rv(m1,m2,m3),rcp(m1,m2,m3),rrp(m1,m2,m3)  &
   ,rpp(m1,m2,m3),rsp(m1,m2,m3),rap(m1,m2,m3),rgp(m1,m2,m3)  &
   ,rhp(m1,m2,m3),q6(m1,m2,m3),q7(m1,m2,m3),rdp(m1,m2,m3)  &
   ,picpi(*),tair(*),til(*),rliq(*),rice(*),qhydm(*)
integer :: i,j,k
real :: tcoal,fracliq,tairstr

do j = ja,jz
   do i = ia,iz

      do k = 1,m1
         picpi(k) = (pi0(k,i,j) + pp(k,i,j)) * cpi
         tair(k) = theta(k,i,j) * picpi(k)
         til(k) = thp(k,i,j) * picpi(k)
         rliq(k) = 0.
         rice(k) = 0.
      enddo

      if (jnmb(1) .ge. 1) then
         do k = 1,m1
            rliq(k) = rliq(k) + rcp(k,i,j)
         enddo
      endif

      if (jnmb(2) .ge. 1) then
         do k = 1,m1
            rliq(k) = rliq(k) + rrp(k,i,j)
         enddo
      endif

      if (jnmb(3) .ge. 1) then
         do k = 1,m1
            rice(k) = rice(k) + rpp(k,i,j)
         enddo
      endif

      if (jnmb(4) .ge. 1) then
         do k = 1,m1
            rice(k) = rice(k) + rsp(k,i,j)
         enddo
      endif

      if (jnmb(5) .ge. 1) then
         do k = 1,m1
            rice(k) = rice(k) + rap(k,i,j)
         enddo
      endif

      if (jnmb(6) .ge. 1) then
         do k = 1,m1
            CALL qtc (q6(k,i,j),tcoal,fracliq)
            rliq(k) = rliq(k) + rgp(k,i,j) * fracliq
            rice(k) = rice(k) + rgp(k,i,j) * (1. - fracliq)
         enddo
      endif

      if (jnmb(7) .ge. 1) then
         do k = 1,m1
            CALL qtc (q7(k,i,j),tcoal,fracliq)
            rliq(k) = rliq(k) + rhp(k,i,j) * fracliq
            rice(k) = rice(k) + rhp(k,i,j) * (1. - fracliq)
         enddo
      endif

      if (jnmb(8) .ge. 1) then
         do k = 1,m1
            rliq(k) = rliq(k) + rdp(k,i,j)
         enddo
      endif

      do k = 1,m1
         qhydm(k) = alvl * rliq(k) + alvi * rice(k)
         rv(k,i,j) = rtp(k,i,j) - rliq(k) - rice(k)
      enddo

      do k = 1,m1
         if (tair(k) .gt. 253.) then
            tairstr = 0.5 * (til(k)  &
               + sqrt(til(k) * (til(k) + cpi4 * qhydm(k))))
         else
            tairstr = til(k) * (1. + qhydm(k) * cp253i)
         endif
         theta(k,i,j) = tairstr / picpi(k)
      enddo

   enddo
enddo

return
END SUBROUTINE wetthrm3

SUBROUTINE temp_adj(m1,m2,m3,thp)
   use ref_sounding
   use mem_grid
   use node_mod
   use rconstants
   use micphys
   implicit none
   
   ! Lucas - variables to do calculation
   integer :: i, j, k, m1, m2, m3
   real :: tscale, count
   real, dimension(m1,iz,jz) :: thp 
   real, dimension(m1) :: thp_diff, tht_local, nudge_vals
   real, dimension(nmachs, m1+1) :: mparr, mparr2
   
   !Lucas - variables to do MPI stuff
   real, allocatable :: buff(:)
   integer :: nwords, nwords_1d, im, im2, ibytes, imsgtype, ihostnum

   ! Lucas - variables for writing of nudging to disk
   integer :: pos, write_flag, read_flag
   logical :: opened

   integer :: hist_start_time

   opened = .FALSE.

   tscale =  itnts ! seconds
   
   call mpi_mean(m1, m2, m3, thp, tht_local)

   thp_diff = tht_local - thpinit
   ! print *, "Setting values"

   ! print *, "DTLT", dtlt
   if (itempnudge.eq.1) then
   do i=ia,iz
      do j=ja, jz
         do k=1,m1
            nudge_vals(k) = (thp_diff(k) * dtlt/tscale)
            thp(k, i, j) = thp(k, i, j) - nudge_vals(k) !(thp_diff(k)*dtlt/tscale)
         end do
      end do
   end do

   hist_start_time = 0 ! time since start of nudge.dat

   else if (itempnudge.eq.2) then
!      if(mynum.eq.1) print *, "Time = ", time
      if(opened.EQV..FALSE.) then
         open(8, FILE='nudge.dat', status='old', action='read')
         opened = .TRUE.
      endif

      ! skip over first i 
      if(hist_start_time.NE.0) then
         do i=1,hist_start_time - 1 
            read(8, *) nudge_vals
         enddo
         hist_start_time=0
      endif
       read(8, *) nudge_vals
       if (mynum.eq.1) print *, "Reading nudge vals ", nudge_vals(1:5)
       do i=ia,iz
         do j=ja,jz
           do k=1,m1
             thp(k,i,j) = thp(k,i,j) - nudge_vals(k) !(tempnudgevals(k)*dtlt/tscale)
           end do
         end do
       end do
   endif


   ! Set to 1 to write temp nudge to file
   ! note: file must exist before writing,
   ! and be empty i.e. `touch nudge.dat`
   write_flag = 0

   ! if on node 1 (and write_flag is True), write file
   if (mynum == 1 .and. write_flag == 1) then
      print *, "Timestep in subroutine is ", ISTP
      
      if(opened.EQV..FALSE.) then
         open(7, FILE='nudge.dat', status='old', action='write', position='append')
         opened = .TRUE.
      endif
      
      write(7, '(200E15.7)') nudge_vals
      
   endif

END SUBROUTINE


! Subroutine to get the initial THP profile from the sounding
! At t=1, this routine is called from rtimh.f90 and sets the 
! variable thpinit, which is then used to calculated nudging
! values in subroutine temp_adj()
subroutine initial_temp_profile(m1, m2, m3, thp)
   use ref_sounding
   use mem_grid
   use node_mod
   use rconstants
   use micphys
   implicit none

   integer :: i, j, k, m1, m2, m3
   real, dimension(m1, iz, jz) :: thp
   real, dimension(m1) :: tht_local
   real :: count

   call mpi_mean(m1, m2, m3, thp, tht_local)

   thpinit = tht_local
end subroutine


! Get the average profile on this node
! Since different nodes might have different 
! number of grid points, get a column of "total"
! values and a count of # of columns.
! This will be used to compute the mean after 
! all nodes have shared this information.
subroutine mpi_mean(m1, m2, m3, var3d, var1d)
   use node_mod
   use mem_grid
   implicit none

   integer :: m1, m2, m3, i, j, k
   real :: dimension(m3, iz, jz)

   real, dimension(m1, iz, jz) :: var3d
   real, dimension(m1) :: var1d
   real :: count

   !Lucas - variables to do MPI stuff
   real, allocatable :: buff(:)
   integer :: nwords, nwords_1d, im, im2, ibytes, imsgtype, ihostnum
   real, dimension(nmachs, m1+1) :: mparr, mparr2

   ! Calculate the local total column value, 
   ! and the number of columns
   var1d = 0
   count = 0
   do i=ia,iz
      do j=ja,jz
         do k=1,m1
            var1d(k) = var1d(k) + var3d(k, i, j)
         end do
         count = count + 1.0
      end do
   end do

   ! create array to pass between nodes w/ MPI
   ! the first 1-m1 is the sum of columns,
   ! and m1 + 1 is used to store the number of columns
   mparr(mynum, 1:m1) = var1d
   mparr(mynum, m1+1) = count

   nwords = nmachs*sizeof(mparr)
   nwords_1d = sizeof(mparr(1, :))


   allocate(buff(nwords))

   ! Make sure that all nodes have the same info
   do im = 1, nmachs
      if (im.eq.mynum) then
         CALL par_init_put(buff, nwords)
         CALL par_put_float(mparr(mynum, :), (m1+1))
         do im2=1, nmachs
            if(mynum.ne.im2) then
               CALL par_send(im2, 10)
            endif
         enddo
      else
         CALL par_get_new(buff, nwords, 10, ibytes, imsgtype, ihostnum)
         CALL par_get_float(mparr(im, :), (m1+1))
      endif
   enddo
   deallocate(buff)

   
   var1d = 0
   count = 0
   ! Decompose mpi values
   do im=1, nmachs
      if(im.ne.mynum) then
         var1d = mparr(im, 1:m1)
         count = mparr(im, m1+1)
      endif
   enddo

   ! Compute the actual mean
   var1d = var1d / count
end subroutine