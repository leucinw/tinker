c
c
c     ###################################################
c     ##  COPYRIGHT (C)  1992  by  Jay William Ponder  ##
c     ##              All Rights Reserved              ##
c     ###################################################
c
c     ################################################################
c     ##                                                            ##
c     ##  module korbs  --  pisystem orbital forcefield parameters  ##
c     ##                                                            ##
c     ################################################################
c
c
c     maxnpi     maximum number of pisystem bond parameter entries
c     maxnpi5    maximum number of 5-membered ring pibond entries
c     maxnpi4    maximum number of 4-membered ring pibond entries
c
c     electron   number of pi-electrons for each atom class
c     ionize     ionization potential for each atom class
c     repulse    repulsion integral value for each atom class
c     sslope     slope for bond stretch vs. pi-bond order
c     sslope5    slope for 5-ring bond stretch vs. pi-bond order
c     sslope4    slope for 4-ring bond stretch vs. pi-bond order
c     tslope     slope for 2-fold torsion vs. pi-bond order
c     tslope5    slope for 5-ring 2-fold torsion vs. pi-bond order
c     tslope4    slope for 4-ring 2-fold torsion vs. pi-bond order
c     kpi        string of atom classes for pisystem bonds
c     kpi5       string of atom classes for 5-ring pisystem bonds
c     kpi4       string of atom classes for 4-ring pisystem bonds
c
c
      module korbs
      implicit none
      integer maxnpi
      integer maxnpi5
      integer maxnpi4
      real*8, allocatable :: electron(:)
      real*8, allocatable :: ionize(:)
      real*8, allocatable :: repulse(:)
      real*8, allocatable :: sslope(:)
      real*8, allocatable :: sslope5(:)
      real*8, allocatable :: sslope4(:)
      real*8, allocatable :: tslope(:)
      real*8, allocatable :: tslope5(:)
      real*8, allocatable :: tslope4(:)
      character*8, allocatable :: kpi(:)
      character*8, allocatable :: kpi5(:)
      character*8, allocatable :: kpi4(:)
      save
      end
