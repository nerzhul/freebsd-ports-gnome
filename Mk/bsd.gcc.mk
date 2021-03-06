#-*- tab-width: 4; -*-
# ex:ts=4
#
# bsd.gcc.mk - Support for smarter USE_GCC usage.
#
# Created by: Edwin Groothuis <edwin@freebsd.org>
#
# To request the use of a current version of GCC, specify USE_GCC=yes in
# your port/system configuration.  This is the preferred use of USE_GCC.
# It uses the canonical version of GCC defined in bsd.default-versions.mk.
#
# USE_GCC=any is similar, except that it also accepts the old GCC 4.2-
# based system compiler in older versions of FreeBSD.
# 
# If your port needs a specific (minimum) version of GCC, you can easily
# specify that with a USE_GCC= statement.  Unless absolutely necessary
# do so by specifying USE_GCC=X+ which requests at least GCC version X.
# To request a specific version omit the trailing + sign.
#
# Examples:
#   USE_GCC=	yes			# port requires a current version of GCC
#							# as defined in bsd.default-versions.mk.
#   USE_GCC=	any			# port requires GCC 4.2 or later.
#   USE_GCC=	9+			# port requires GCC 9 or later.
#   USE_GCC=	8			# port requires GCC 8.
#
# If you are wondering what your port exactly does, use "make test-gcc"
# to see some debugging.
#
# $FreeBSD$

GCC_Include_MAINTAINER=		gerald@FreeBSD.org

# All GCC versions supported by the ports framework.  Keep them in
# ascending order and in sync with the table below. 
# When adding a version, please keep the comment in
# Mk/bsd.default-versions.mk in sync.
GCCVERSIONS=	040200 040800 070000 080000 090000

# The first field is the OSVERSION in which it disappeared from the base.
# The second field is the version as USE_GCC would use.
GCCVERSION_040200=	9999999 4.2
GCCVERSION_040800=	      0 4.8
GCCVERSION_070000=	      0 7
GCCVERSION_080000=	      0 8
GCCVERSION_090000=	      0 9

# No configurable parts below this. ####################################
#

.if defined(USE_GCC) && ${USE_GCC} == yes
USE_GCC=	${GCC_DEFAULT}+
.endif

# Extract the fields from GCCVERSION_...
.for v in ${GCCVERSIONS}
. for j in ${GCCVERSION_${v}}
.  if !defined(_GCCVERSION_${v}_R)
_GCCVERSION_${v}_R=	${j}
.  elif !defined(_GCCVERSION_${v}_V)
_GCCVERSION_${v}_V=	${j}
.  endif
. endfor
.endfor

.if defined(USE_GCC) && !defined(FORCE_BASE_CC_FOR_TESTING)

. if ${USE_GCC} == any

# Enable the clang-is-cc workaround.  Default to the last GCC imported
# into base.
_USE_GCC:=	4.2
_GCC_ORLATER:=	true

. else # ${USE_GCC} == any

# See if we can use a later version or exclusively the one specified.
_USE_GCC:=	${USE_GCC:S/+//}
.if ${USE_GCC} != ${_USE_GCC}
_GCC_ORLATER:=	true
.endif

. endif # ${USE_GCC} == any

# See whether we have the specific version requested installed already
# and save that into _GCC_FOUND.  In parallel, check if USE_GCC refers
# to a valid version to begin with.
.for v in ${GCCVERSIONS}
. if ${_USE_GCC}==${_GCCVERSION_${v}_V}
_GCCVERSION_OKAY=	true
.  if exists(${LOCALBASE}/bin/gcc${_GCCVERSION_${v}_V:S/.//})
_GCC_FOUND:=		${_USE_GCC}
.  elif ${OSVERSION} < ${_GCCVERSION_${v}_R} && exists(/usr/bin/gcc)
_GCC_FOUND:=		${_USE_GCC}
.  endif
. endif
.endfor

.if !defined(_GCCVERSION_OKAY)
IGNORE=	Unknown version of GCC specified (USE_GCC=${USE_GCC})
.endif

# If the GCC package defined in USE_GCC does not exist, but a later
# version is allowed (for example 8+), go and use the default.
.if defined(_GCC_ORLATER)
. if !defined(_GCC_FOUND) && ${_USE_GCC} < ${GCC_DEFAULT}
_USE_GCC:=	${GCC_DEFAULT}
. endif
.endif # defined(_GCC_ORLATER)

.endif # defined(USE_GCC)


.if defined(_USE_GCC)
# A concrete version has been selected.  Determine if the installed OS 
# features this version in the base, and if not then set proper ports
# dependencies, CC, CXX, CPP, and flags.
.for v in ${GCCVERSIONS}
. if ${_USE_GCC} == ${_GCCVERSION_${v}_V}
.  if ${OSVERSION} > ${_GCCVERSION_${v}_R} || !exists(/usr/bin/gcc)
V:=			${_GCCVERSION_${v}_V:S/.//}
_GCC_PORT_DEPENDS:=	gcc${V}
_GCC_PORT:=		gcc${V}
CC:=			gcc${V}
CXX:=			g++${V}
CPP:=			cpp${V}
_GCC_RUNTIME:=		${LOCALBASE}/lib/gcc${V}
.   if ${PORTNAME} == gcc
# We don't want the rpath stuff while building GCC itself
# so we do not set the FLAGS as done in the else part.
# When building a GCC, we want the target libraries to be used and not the
# host GCC libraries.
.   else
CFLAGS+=		-Wl,-rpath=${_GCC_RUNTIME}
CXXFLAGS+=		-Wl,-rpath=${_GCC_RUNTIME}
LDFLAGS+=		-Wl,-rpath=${_GCC_RUNTIME} -L${_GCC_RUNTIME}
.   endif
.  else # Use GCC in base.
CC:=			gcc
CXX:=			g++
.   if exists(/usr/bin/gcpp)
CPP:=			gcpp
.   else
CPP:=			cpp
.   endif
.  endif # Use GCC in base.
. endif # ${_USE_GCC} == ${_GCCVERSION_${v}_V}
.endfor
.undef V

# Now filter unsupported flags for CC and CXX.
CFLAGS:=		${CFLAGS:N-mretpoline}
CXXFLAGS:=		${CXXFLAGS:N-mretpoline}

.if defined(_GCC_PORT_DEPENDS)
BUILD_DEPENDS+=	${_GCC_PORT_DEPENDS}:lang/${_GCC_PORT}
RUN_DEPENDS+=	${_GCC_PORT_DEPENDS}:lang/${_GCC_PORT}
# Later GCC ports already depend on binutils; make sure whatever we
# build leverages this as well.
USE_BINUTILS=	yes
.endif
.endif # defined(_USE_GCC) && !defined(FORCE_BASE_CC_FOR_TESTING)


test-gcc:
	@echo USE_GCC=${USE_GCC}
.if defined(IGNORE)
	@echo "IGNORE: ${IGNORE}"
.else
.if defined(USE_GCC)
.if defined(_GCC_ORLATER)
	@echo Port can use later versions.
.else
	@echo Port cannot use later versions.
.endif
.for v in ${GCCVERSIONS}
	@echo -n "GCC version: ${_GCCVERSION_${v}_V} "
	@echo "- OSVERSION up to ${_GCCVERSION_${v}_R}"
.endfor
	@echo Using GCC version ${_USE_GCC}
.endif
	@echo CC=${CC} - CXX=${CXX} - CPP=${CPP}
	@echo CFLAGS=\"${CFLAGS}\"
	@echo CXXFLAGS=\"${CXXFLAGS}\"
	@echo LDFLAGS=\"${LDFLAGS}\"
	@echo "BUILD_DEPENDS=${BUILD_DEPENDS}"
	@echo "RUN_DEPENDS=${RUN_DEPENDS}"
.endif
