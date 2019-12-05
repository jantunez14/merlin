###########################################################################
## The system as a whole and most of the files in it are distributed      #
## under the following copyright and conditions                           #
##                                                                        #
##                The HMM-based Speech Synthesis Systems                  #
##             for the Blizzard Challenge and EMIME project               #
##                Centre for Speech Technology Research                   #
##                     University of Edinburgh, UK                        #
##                      Copyright (c) 2007-2008                           #
##                        All Rights Reserved.                            #
##                                                                        #
##  Permission is hereby granted, free of charge, to use and distribute   #
##  this software and its documentation without restriction, including    #
##  without limitation the rights to use, copy, modify, merge, publish,   #
##  distribute, sublicense, and/or sell copies of this work, and to       #
##  permit persons to whom this work is furnished to do so, subject to    #
##  the following conditions:                                             #
##   1. The code must retain the above copyright notice, this list of     #
##      conditions and the following disclaimer.                          #
##   2. Any modifications must be clearly marked as such.                 #
##   3. Original authors' names are not deleted.                          #
##   4. The authors' names are not used to endorse or promote products    #
##      derived from this software without specific prior written         #
##      permission.                                                       #
##                                                                        #
##  THE UNIVERSITY OF EDINBURGH AND THE CONTRIBUTORS TO THIS WORK         #
##  DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING       #
##  ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT    #
##  SHALL THE UNIVERSITY OF EDINBURGH NOR THE CONTRIBUTORS BE LIABLE      #
##  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES     #
##  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN    #
##  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,           #
##  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF        #
##  THIS SOFTWARE.                                                        #
###########################################################################
##                         Author: Junichi Yamagishi                      #
##                         Date:   25 Feb 2009                            #
##                         Contact: jyamagis@inf.ed.ac.uk                 #
###########################################################################
##                                                                        #
##                  Speech Synthesis using hts_engine                     #
##                                                                        #
###########################################################################

#! /bin/csh -f 





if ($# == 0) then
    echo "usage: % csh synthesis-hts_engine.sh -hmmdir HMMdir -labdir labeldir -outdir outdir -shift int -order int -spec int"
    exit
endif

# Input and output directories 
set HMMdir   = "."   # directory of HMM 
set labeldir = "."   # directory of input label 
set outdir   = "."   # directory of output directory 

# Configuration variables
set shift     = 5   # frame shift in ms
set method    = 1   # Spectral analysis method 
                    # 1) Mel-cepstrum 2) Mel-generalized cepstrum 3) Mel-LSP 4) MGC-LSP 
set order     = 59  # mel-cepstral analysis order 
set mgcgamma  = 3 
set rate      = 48000    # Sampling rate 
set scale     = 3        # Variable for scale (1: Mel 2:Bark by Junichi 3: Bark by Julius 4:ERB by Julius)
                         # Julius Smith "Bark and ERB Bilinear transforms 
                         # IEEE Speech & Audio Proc Vol.7 No.6 Nov. 1999

set f0scale = 3          # flag for scale for F0 transform 
                         # 1) log scale
                         # 2) generalized log scale
                         # 3) mel scale 

	echo ""
	echo "F0 transform:"
    set lambda = -1.0
    echo "Mel transform"

    set HMMdir = $2
#    echo "HMMdir = $HMMdir"
    set labeldir = $4
#    echo "labeldir = $labeldir"
    set outdir = $6
#    echo "outdir = $outdir"

#set path = ( /afs/inf.ed.ac.uk/user/v/v1jmont2/v1jmont2-afs/voiceCloning/VCTK2/bin /afs/inf.ed.ac.uk/user/v/v1jmont2/v1jmont2-afs/voiceCloning/VCTK2/synthesis-hts_engine_straight $path )
set path = (. $path )
set hts   = hts_engine_straight
set resyn = synthesis_fft

mkdir -p $outdir

    set fftlen = 4096
    echo "Bark scale (by Julius)"
    set alpha  = "0.77"

echo "Speech synthesis using HMMs (hts_engine)"
echo "Sampling rate: $rate  Frame shift: $shift ms  Analysis order: $order"
echo "Alpha for all-pass filter:$alpha"
#echo ""

set krate=`echo "$rate / 1000" | bc` # e.g. Frame shift in point (80 = 16000 * 0.005)

foreach lab ($labeldir/*.lab)
    set f0    = $outdir/$lab:t:r.f0
    set mcep  = $outdir/$lab:t:r.mcep
    set apf   = $outdir/$lab:t:r.apf
    set sspec = $outdir/$lab:t:r.spec
    set wav   = $outdir/$lab:t:r.wav


	# echo "Executing mgc2sp"
    # time mgc2sp &
	
	echo "$hts -td $HMMdir/tree-duration.inf -tf $HMMdir/tree-logF0.inf -tm $HMMdir/tree-mcep.inf -ta $HMMdir/tree-bndap.inf -md $HMMdir/duration.pdf -mf $HMMdir/logF0.pdf -mm $HMMdir/mcep.pdf -ma $HMMdir/bndap.pdf -df $HMMdir/logF0_d1.win -df $HMMdir/logF0_d2.win -dm $HMMdir/mcep_d1.win -dm $HMMdir/mcep_d2.win -da $HMMdir/bndap_d1.win -da $HMMdir/bndap_d2.win -gf $HMMdir/gv-lf0.pdf -gm $HMMdir/gv-mcep.pdf -ga $HMMdir/gv-bndap.pdf -e  $lambda \
		-u 0.5 \
        -of $f0 \
        -om $mcep \
        -oa $apf \
        $lab"
#set ini=`date +%s.%N`
    time $hts \
        -td $HMMdir/tree-duration.inf \
        -tf $HMMdir/tree-logF0.inf \
        -tm $HMMdir/tree-mcep.inf \
        -ta $HMMdir/tree-bndap.inf \
        -md $HMMdir/duration.pdf \
        -mf $HMMdir/logF0.pdf \
        -mm $HMMdir/mcep.pdf \
        -ma $HMMdir/bndap.pdf \
        -df $HMMdir/logF0_d1.win \
        -df $HMMdir/logF0_d2.win \
        -dm $HMMdir/mcep_d1.win \
        -dm $HMMdir/mcep_d2.win \
        -da $HMMdir/bndap_d1.win \
        -da $HMMdir/bndap_d2.win \
        -gf $HMMdir/gv-lf0.pdf \
        -gm $HMMdir/gv-mcep.pdf \
        -ga $HMMdir/gv-bndap.pdf \
        -e  $lambda \
        -u 0.5 \
        -of $f0 \
        -om $mcep \
        -oa $apf \
		-r 0.1 \
        $lab >tmp/hts_engine_straight.log

#set fin=`date +%s.%N`
#set dur=`echo "$fin - $ini" | bc`
#echo "TIME: $hts execution time: $dur"

#set ini=`date +%s.%N`
    time x2x +fd $apf  > $apf.double     #Convert float to double
    time x2x +fa $f0   > $f0.txt         #Convert float to ASCII
#set fin=`date +%s.%N`
#set dur=`echo "$fin - $ini" | bc`
#echo "TIME: $hts x2x execution time: $dur"

##DEPURAR	

# # define default...
# set text = "Press the <ENTER> key to continue..."
# # accept user's alternative if offered...
# #if ($#argv > 0) set text = "$* >>"
# printf "\n$text"
# set junk = ($<)
# ##DEPURAR

    # Convert given mel-cepstrum or LSP to the smoothed spectrum
    echo "Spectral analysis method: Mel-cepstral analysis"
    #        mgc2sp -a $alpha -g 0 -m $order -l $fftlen -o 2 $mcep |\
    #        x2x +fd > $sspec.double

#----------------------------------#
#       Start server               #
#----------------------------------#
echo "	== Executing mgc2sp =="
#set ini=`date +%s.%N`
  time mgc2sp/mgc2sp 1 &
#set fin=`date +%s.%N`
#set dur=`echo "$fin - $ini" | bc`
#echo "TIME: mgc2sp execution time: $dur"

sleep 0.5 #Need to sleep so client does not connect before server is ready

#----------------------------------#
#       Start client               #
#----------------------------------#

echo "	== Executing mcpf =="	
#set ini=`date +%s.%N`
   time mcpf/mcpf $mcep 1
#set fin=`date +%s.%N`
#set dur=`echo "$fin - $ini" | bc`
#echo "TIME: mcpf mgc2sp execution time: $dur"
#set tmp="/autofs/home/gth04a/beatrizbarakat/tmp.bin"

# ##DEPURAR	

# # define default...
# set text = "Press the <ENTER> key to continue..."
# # accept user's alternative if offered...
# #if ($#argv > 0) set text = "$* >>"
# printf "\n$text"
# set junk = ($<)
# # ##DEPURAR


set tmp2="./tmp/tmp2.bin"
echo "	== Executing x2x =="
#set ini=`date +%s.%N`
    time x2x +fd $tmp2 > $sspec.double
#set fin=`date +%s.%N`
#set dur=`echo "$fin - $ini" | bc`
#echo "TIME: x2x execution time: $dur"
	#mcpf-mgc2sp $mcep | x2x +fd > $sspec.double

# #DEPURAR	
	# echo "$sspec"

# # define default...
# set text = "Press the <ENTER> key to continue..."
# # accept user's alternative if offered...
# #if ($#argv > 0) set text = "$* >>"
# printf "\n$text"
# set junk = ($<)
# #DEPURAR

# sleep 2
# ls -al $f0.txt $apf.double $sspec.double
    echo "$resyn -f $rate -fftl $fftlen -spec -order $order -shift $shift -sigp 1.2 -sd 0.5 -cornf 4000 -bw 70.0 -delfrac 0.2 -bap -apfile $apf.double $f0.txt $sspec.double $wav"

#set ini=`date +%s.%N`
		time $resyn \
        -f $rate \
        -fftl $fftlen \
        -spec \
        -order $order \
        -shift $shift \
        -sigp 1.2 \
        -sd 0.5 \
        -cornf 4000 \
        -bw 70.0 \
        -delfrac 0.2 \
        -bap \
        -apfile $apf.double \
        $f0.txt \
        $sspec.double \
        $wav
#set fin=`date +%s.%N`
#set dur=`echo "$fin - $ini" | bc`
#echo "TIME: $resyn execution time: $dur"

    #rm -f $f0 $mcep $apf $f0.txt $sspec.double $apf.double
#echo $wav
end
