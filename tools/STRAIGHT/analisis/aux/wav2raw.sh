#!/bin/csh -f
# ----------------------------------------------------------------- #
#             The Speech Signal Processing Toolkit (SPTK)           #
#             developed by SPTK Working Group                       #
#             http://sp-tk.sourceforge.net/                         #
# ----------------------------------------------------------------- #
#                                                                   #
#  Copyright (c) 1984-2007  Tokyo Institute of Technology           #
#                           Interdisciplinary Graduate School of    #
#                           Science and Engineering                 #
#                                                                   #
#                1996-2011  Nagoya Institute of Technology          #
#                           Department of Computer Science          #
#                                                                   #
# All rights reserved.                                              #
#                                                                   #
# Redistribution and use in source and binary forms, with or        #
# without modification, are permitted provided that the following   #
# conditions are met:                                               #
#                                                                   #
# - Redistributions of source code must retain the above copyright  #
#   notice, this list of conditions and the following disclaimer.   #
# - Redistributions in binary form must reproduce the above         #
#   copyright notice, this list of conditions and the following     #
#   disclaimer in the documentation and/or other materials provided #
#   with the distribution.                                          #
# - Neither the name of the SPTK working group nor the names of its #
#   contributors may be used to endorse or promote products derived #
#   from this software without specific prior written permission.   #
#                                                                   #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND            #
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,       #
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF          #
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          #
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS #
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,          #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   #
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,     #
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON #
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,   #
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    #
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           #
# POSSIBILITY OF SUCH DAMAGE.                                       #
# ----------------------------------------------------------------- #
#                                                                   #
#                                      Mar. 2010  A. Tamamori       #

onintr clean

set path    = ( /home/jantunez/merlin/tools/STRAIGHT/analisis/aux $path )
set sptkver = '3.5'
set cvsid   = '$Id: wav2raw.in,v 1.10 2011/12/19 06:00:35 mataki Exp $'


set cmnd	= $0
set cmnd	= $cmnd:t

set file
set flagfile    = 0

set directory
set flagdirectory = 0


set swab		= 0
set normalization	= 0
set normalization_all = 0
set OutputType = s
set OutMaxVal = 32767
set data_position
set READfmt = 0
set ENTERdatachunk = 0

@ i = 0
while ($i < $#argv)
	@ i++
	switch ($argv[$i])
	case -swab:
		set swab = 1
		breaksw
    case +c:
        set OutputType = c
        set OutMaxVal = 127
        breaksw
	case +s:
		set OutputType = s
        set OutMaxVal = 32767
		breaksw
    case +i3:
        set OutputType = i3
        set OutMaxVal = 8388067
        breaksw
	case +i:
		set OutputType = i
        set OutMaxVal = 2147483647
		breaksw
	case +l:
		set OutputType = l
        set OutMaxVal = 2147483647
		breaksw
	case +C:
		set OutputType = C
        set OutMaxVal = 255
		breaksw
	case +S:
		set OutputType = S
        set OutMaxVal = 65535
		breaksw
	case +I3:
		set OutputType = I3
        set OutMaxVal = 16776135
		breaksw
	case +I:
		set OutputType = I
        set OutMaxVal = 4294967296
		breaksw
	case +L:
		set OutputType = L
        set OutMaxVal = 4294967296
		breaksw
	case +f:
		set OutputType = f
        set OutMaxVal = 1
		breaksw
	case +d:
		set OutputType = d
        set OutMaxVal = 1
		breaksw
	case +a:
		set OutputType = a
		breaksw		
	case -d:
		@ i++
		set directory = $argv[$i]
		set flagdirectory = 1
		if ( ! -d $argv[$i] ) then
			echo2 "${cmnd}: Can't find directory "'"'"$directory"'"'" \!"
			set exit_status = 1
			goto usage
		endif
		breaksw
	case -n:
		set normalization = 1
		breaksw
	case -N:
		set normalization = 1
		set normalization_all = 1
		breaksw
	case -h:
		set exit_status = 0
		goto usage
		breaksw
	default:
		set file = ( $file $argv[$i] )
		set flagfile = 1
		if ( ! -f $argv[$i] ) then
			echo2 "${cmnd}: Can't open file "'"'"$file"'"'" \!"
			set exit_status = 1
			goto usage
		endif
		breaksw
	endsw
end

goto main

usage:
        echo2 ''
        echo2 " $cmnd - wav to raw "
        echo2 ''
        echo2 '  usage:'
        echo2 "       $cmnd [ options ] [ infile(s) ]"
        echo2 '  options:'
        echo2 '       -swab         : change "endian"                           [FALSE]'
        echo2 '       -d d          : destination directory                     [N/A]'
        echo2 '       -n            : normalization with the maximum value'
        echo2 '                       according to bit/sample of the wav file'
        echo2 '                       if max >= 255 (8bit), 32767 (16bit),'
        echo2 '                       8388067 (24bit), 2147483647 (32bit).'
        echo2 '       -N            : normalization with the maximum value      [FALSE]'
        echo2 '       +type         : output data type                          [s]'
        echo2 '                        c  (char)         C  (unsigned char) '
        echo2 '                        s  (short)        S  (unsigned short)'
        echo2 '                        i3 (int, 3byte)   I3 (unsigned int, 3byte)'
        echo2 '                        i  (int)          I  (unsigned int)'
        echo2 '                        l  (long)         L  (unsigned long)'
        echo2 '                        f  (float)        d  (double)'
        echo2 '                        a  (ascii)'
        echo2 '       -h            : print this message'
        echo2 '  infile(s):'
        echo2 '       rawfile                                                   [N/A]'
        echo2 '  output:'
        echo2 "       $cmnd removes RIFF header(s) from input wav file(s)."
        echo2 '                                                         '
        echo2 '       The outfile has an extention ".raw", e.g.,'
        echo2 '          sample.m15 ---> sample.m15.raw'
        echo2 '                                                         '
        echo2 '       If the infile has an extention ".wav",'
        echo2 '       the extention is converted into ".raw", e.g.,'
        echo2 '          sample.m15.wav ---> sample.m15.raw'
        echo2 '                                                         '
        echo2 '       The outfile is stored in the same directory'
        echo2 '       as the infile.'
        echo2 '       However, once a destination directory is specified,'
        echo2 '       all raw files are stored in that directory.'
        echo2 ''
        echo2 " SPTK: version $sptkver"
        echo2 " CVS Info: $cvsid"
        echo2 ''
exit $exit_status

main:

foreach f ($file)
    set tmp = `bcut +c -s 4 -e 7 $f | x2x +Ia`
    @ FileSize = $tmp + 8

    @ Current = 12
    @ Rest = $FileSize
    while( $Rest > 0 )
        #Read the chunk ID (4byte)
        set i = 0; set tmp = $Current; set ChunkID
        while( $i < 4 )
            set tmp2 = `bcut +c -s $tmp -e $tmp $f | x2x +Ca`
            set ChunkID = ${ChunkID}`printf "%X" $tmp2`
            @ i++; @ tmp++
        end
        @ Current = $Current + 4

        #Read the chunk size (4byte)
        @ tmp = $Current + 3
        set ChunkSize = `bcut +c -s $Current -e $tmp $f | x2x +Ia`
        @ Current = $Current + 4

        switch( $ChunkID )
        case 666D7420: #The chunk ID is "fmt " (ASCII code, hexadecimal number)
            @ tmp = $Current + 1
            set FormatID = `bcut +c -s $Current -e $tmp $f | x2x +Sa`

            @ Current = $Current + 14
            @ tmp = $Current + 1
            set BitPerSample = `bcut +c -s $Current -e $tmp $f | x2x +Sa`
            switch( $BitPerSample )
            case  8:
                set InputType = c
                set MaxVal = 255
                breaksw
            case 16:
                set InputType = s
                set MaxVal = 32767
                breaksw
            case 24:
                set InputType = i3
                set MaxVal = 8388067
                breaksw
            case 32:
                if ( $FormatID == 1 ) then # PCM
                    set InputType = i
                    set MaxVal = 2147483647
                else if ( $FormatID == 3 ) then # IEEE float
                    set InputType = f
                    set MaxVal = 1
                else
                    echo2 "Format id $FormatID is not acceptable!"
                    exit
                endif
                breaksw
            endsw

            @ Current = $Current + 2

            set READfmt = 1 # enable to read "data" chunk
            if ( $ENTERdatachunk == 0) then
                breaksw
            else
                # if "data" chunk has been read
                @ Current = $data_position
                # immediately read "data" chunk. no need to use 'breaksw'.
            endif

        case 64617461: #The chunk ID is "data" (ASCII code, hexadecimal number)
            if ( $READfmt == 0 ) then
                set ENTERdatachunk = 1
                set data_position = $Current
                breaksw
            endif
            @ tmp = $Current + $ChunkSize
            if ( $normalization ) then
                if ( $FormatID == 3) then
                    if ( $swab ) then
                        bcut +c -s $Current -e $tmp $f | swab |\
                        sopr -m ${OutMaxVal} > /tmp/{$f:t}.$$.tmp
                    else
                        bcut +c -s $Current -e $tmp $f |\
                        sopr -m ${OutMaxVal} > /tmp/{$f:t}.$$.tmp
                    endif

                    set max = `minmax < /tmp/{$f:t}.$$.tmp | sopr -ABS |\
                               minmax | bcut -s 1 | x2x +fa %.100f`

                    if ( $normalization_all || `echo "$max < 0" | bc -l` ) then
                        sopr -m $MaxVal -d $max < /tmp/{$f:t}.$$.tmp |\
                        x2x -r +f${OutputType} > /tmp/{$f:t}.$$.raw
                    else
                        x2x -r +f${OutputType} < /tmp/{$f:t}.$$.tmp |\
                            > /tmp/{$f:t}.$$.raw
                    endif
                else
                    if ( $swab ) then
                        bcut +c -s $Current -e $tmp $f | swab +$InputType |\
                        x2x +${InputType}f > /tmp/{$f:t}.$$.tmp
                    else
                        bcut +c -s $Current -e $tmp $f |\
                        x2x +${InputType}f > /tmp/{$f:t}.$$.tmp
                    endif

                    set max = `minmax < /tmp/{$f:t}.$$.tmp | sopr -ABS |\
                               minmax | bcut -s 1 | x2x +fa %.100f`

                    if ( $normalization_all || `echo "$max < 0" | bc -l` ) then
                        sopr -m $MaxVal -d $max < /tmp/{$f:t}.$$.tmp |\
                        x2x -r +f${OutputType} > /tmp/{$f:t}.$$.raw
                    else
                        x2x -r +f${OutputType} < /tmp/{$f:t}.$$.tmp |\
                            > /tmp/{$f:t}.$$.raw
                    endif
                endif

                /bin/rm -f /tmp/{$f:t}.$$.tmp
            else #No normalization
                if ( $FormatID == 3) then
                    if ( $swab ) then
                        bcut +c -s $Current -e $tmp $f | swab |\
                        sopr -m ${OutMaxVal} |\
                        x2x -r +f${OutputType} > /tmp/{$f:t}.$$.raw
                     else
                        bcut +c -s $Current -e $tmp $f |\
                        sopr -m ${OutMaxVal} |\
                        x2x -r +f${OutputType} > /tmp/{$f:t}.$$.raw
                     endif
                else
                    if ( $swab ) then
                        bcut +c -s $Current -e $tmp $f | swab +$InputType |\
                        x2x -r +${InputType}${OutputType} > /tmp/{$f:t}.$$.raw
                    else
                        bcut +c -s $Current -e $tmp $f |\
                        x2x -r +${InputType}${OutputType} > /tmp/{$f:t}.$$.raw
                    endif
                endif
            endif

            if ( $f:e == "wav" ) then
                if ( $flagdirectory ) then
                    set outfile = $directory/$f:t:r.raw
                else
                    set outfile = $f:r.raw
                endif
            else
                if ( $flagdirectory ) then
                    set outfile = $directory/$f:t.raw
                else
                    set outfile = $f.raw
                endif
            endif

            /bin/mv /tmp/{$f:t}.$$.raw $outfile
            @ Current = $Current + $ChunkSize

            breaksw
       
        default:
            @ Current = $Current + $ChunkSize
            breaksw

        endsw # end of switch($ChunkID)

        @ Rest = $FileSize - $Current
    end
end

clean:
/bin/rm -f /tmp/{$f:t}.$$.raw /tmp/{$f:t}.$$.tmp
