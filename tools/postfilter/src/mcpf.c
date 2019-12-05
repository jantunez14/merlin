/*
  ----------------------------------------------------------------
	Speech Signal Processing Toolkit (SPTK): version 3.0
			 SPTK Working Group

		   Department of Computer Science
		   Nagoya Institute of Technology
				and
    Interdisciplinary Graduate School of Science and Engineering
		   Tokyo Institute of Technology
		      Copyright (c) 1984-2000
			All Rights Reserved.

  Permission is hereby granted, free of charge, to use and
  distribute this software and its documentation without
  restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of this work, and to permit persons to whom this
  work is furnished to do so, subject to the following conditions:

    1. The code must retain the above copyright notice, this list
       of conditions and the following disclaimer.

    2. Any modifications must be clearly marked as such.

  NAGOYA INSTITUTE OF TECHNOLOGY, TOKYO INSITITUTE OF TECHNOLOGY,
  SPTK WORKING GROUP, AND THE CONTRIBUTORS TO THIS WORK DISCLAIM
  ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT
  SHALL NAGOYA INSTITUTE OF TECHNOLOGY, TOKYO INSITITUTE OF
  TECHNOLOGY, SPTK WORKING GROUP, NOR THE CONTRIBUTORS BE LIABLE
  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
  DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
  PERFORMANCE OF THIS SOFTWARE.
 ----------------------------------------------------------------
*/

/************************************************************************
*									*
*    Postfiltering for Mel-Cepstal Coefficients (before MLSA Filter)	*
*									*
*					2003.2  T.Masuko		*
*									*
*	usage:								*
*		pfmc [ options ] [ infile ] > stdout			*
*	options:							*
*		-a alpha :  all-pass constant		[0.35]		*
*		-m m     :  order of mel cepstrum	[25]		*
*		-b beta  :  postfilter coefficent	[0.3]		*
*		-l l     :  length of impulse responce	[64]		*
*	infile:								*
*		mel cepstral coefficients				*
*		    , c~(0), c~(1), ..., c~(M),				*
*	stdout:								*
*		mel cepstral coefficients with postfiltering		*
*		    , c~(0), c~(1), ..., c~(M),				*
*	require:							*
*		mc2b(), b2mc(), freqt(), c2ir()				*
*									*
************************************************************************/

static char *rcs_id = "$Id:";


/*  Standard C Libraries  */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <SPTK.h>

/*  Required Functions  */
void	mc2b(), b2mc(), freqt(), c2ir();


/*  Default Values  */
#define	ALPHA		0.35
#define ORDER		25
#define	BETA		0.3
#define	IRLENG		64


/*  Command Name  */
char	*cmnd;


void usage(int status)
{
    fprintf(stderr, "\n");
    fprintf(stderr, " %s - transform mel cepstrum \n",cmnd);
    fprintf(stderr, "          to MLSA digital filter coefficients\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "  usage:\n");
    fprintf(stderr, "       %s [ options ] [ infile ] > stdout\n", cmnd);
    fprintf(stderr, "  options:\n");
    fprintf(stderr, "       -a a  : all-pass constant          [%g]\n", ALPHA);
    fprintf(stderr, "       -m m  : order of mel-cepstrum      [%d]\n", ORDER);
    fprintf(stderr, "       -b b  : postfilter coefficent      [%g]\n", BETA);
    fprintf(stderr, "       -l l  : length of impulse responce [%d]\n", IRLENG);
    fprintf(stderr, "       -h    : print this message\n");
    fprintf(stderr, "  infile:\n");
    fprintf(stderr, "       mel-cepstrum (float)          [stdin]\n");
    fprintf(stderr, "  stdout:\n");
    fprintf(stderr, "       MLSA filter coefficients (float)\n");
    fprintf(stderr, "\n");
    exit(status);
}

void main(int argc, char **argv)
{
    int		m = ORDER, irleng = IRLENG, m1, k;
    FILE	*fp = stdin;
    double	a = ALPHA, beta = BETA, *x, atof();
    double	e1, e2, b2en();
    
    if ((cmnd = strrchr(argv[0], '/')) == NULL)
	cmnd = argv[0];
    else
	cmnd++;
    while (--argc)
	if (**++argv == '-') {
	    switch (*(*argv+1)) {
	        case 'a':
		    a = atof(*++argv);
		    --argc;
		    break;
		case 'm':
		    m = atoi(*++argv);
		    --argc;
		    break;
	        case 'b':
		    beta = atof(*++argv);
		    --argc;
		    break;
		case 'l':
		    irleng = atoi(*++argv);
		    --argc;
		    break;
		case 'h':
		    usage(0);
		default:
		    fprintf(stderr, "%s : Invalid option '%c' !\n", cmnd, *(*argv+1));
		    usage(1);
		}
	}
	else 
	    fp = getfp(*argv, "r");

    m1 = m + 1;

    x = dgetmem(m1);

    while (freadf(x, sizeof(*x), m1, fp) == m1){
	mc2b(x, x, m, a);
        e1 = b2en(x, m, a, irleng);
        x[1] -= beta * a * x[2];
        for(k = 2; k <= m; k++)
          x[k] *= (1.0 + beta);
        e2 = b2en(x, m, a, irleng);
        x[0] += log(e1/e2)/2;
	b2mc(x, x, m, a);
	fwritef(x, sizeof(*x), m1, stdout);
    }
    exit(0);
}

double b2en(b, m, a, irleng)
double *b, a;
int m, irleng;
{
  double en;
  int k;
  static double *mc = NULL, *cep, *ir;
  static int o = 0;

  if (o < m) {
    if (mc != NULL) {
      free(mc);
    }
    if ((mc = (double *)calloc((m+1)+2*irleng,sizeof(double))) == NULL) {
      fprintf(stderr, "Memory allocation error !\n");
      exit (1);
    }
    cep = mc + m+1;
    ir = cep + irleng;
  }

  b2mc(b, mc, m, a);
  freqt(mc, m, cep, irleng-1, -a);
  c2ir(cep, irleng, ir, irleng);
  en = 0.0;
  for (k=0;k<irleng;k++)
    en += ir[k] * ir[k];

  return(en);
}
