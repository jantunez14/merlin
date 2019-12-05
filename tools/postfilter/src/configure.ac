#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT(Postfilter, 1.0, BUG-REPORT-ADDRESS)
AC_CONFIG_SRCDIR([mcpf.c])
AC_CONFIG_SRCDIR([lsppf.c])
AM_INIT_AUTOMAKE()
AM_INIT_AUTOMAKE()

# Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL

# Checks for libraries.
AC_CHECK_LIB([m], [main])
AC_CHECK_LIB([SPTK], [main])

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([stdio.h string.h math.h sys/types.h sys/stat.h])

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.
AC_CHECK_FUNCS([strrchr])

AC_OUTPUT(Makefile)
