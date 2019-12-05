#!/bin/bash
#$ -S /bin/bash
###########################################################################
##                                                                        #
##                The HMM-based Speech Synthesis Systems                  #
##                Centre for Speech Technology Research                   #
##                     University of Edinburgh, UK                        #
##                      Copyright (c) 2007-2011                           #
##                        All Rights Reserved.                            #
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
##                         Date:   31 October 2011                        #
##                         Contact: jyamagis@inf.ed.ac.uk                 #
###########################################################################


# Check Number of Args
if (( "$#" < "2" )); then
   echo "Usage:"
   echo "$0 config_file wav"
   exit 1
fi

# Load configure file and wav
CONFIG_FILE=$1
. ${CONFIG_FILE}
if (( $?>0 ));then echo "Error; exiting."; exit 1; fi
wav=$2

# Set command path
export PATH=${VC_PATH}:${PATH}
export PATH=${EST_PATH}:${PATH}

# Create directories if necessary 
mkdir -p ${TMP_DIR}
mkdir -p ${TMP_DIR}/raw
mkdir -p ${TMP_DIR}/cmp
mkdir -p ${TMP_DIR}/vad
mkdir -p ${TMP_DIR}/gv
mkdir -p ${TMP_DIR}/abs
mkdir -p ${CMP_OUTPUT}
mkdir -p ${HTS_OUTPUT}
mkdir -p ${GV_OUTPUT}
mkdir -p ${VAD_OUTPUT}
mkdir -p ${RAW_OUTPUT}
mkdir -p ${MCEP_OUTPUT}
mkdir -p ${F0_OUTPUT}
mkdir -p ${BAP_OUTPUT}

echo "wav2feature Start feature analysis"
# Start feature analysis
#echo "...Check speech active level and conduct rate/bit/channel conversion if necessary..."
# Suffix of downsampled raw files (in TMP_DIR)
suffix=`echo $rate | awk '{print "raw_"$1/1000"k"}'`

chmod -x $wav
base=`basename $wav .wav`

# check sampling rate 
inputrate=`ch_wave -info $wav | grep "Sample rate" | awk '{print $3}'`

echo "wav2feature feature analysis 2"

# Precision conversion to 16 bits with normalisation if necessary and take the left channel out
echo "wav2raw +s -N -d ${TMP_DIR}/raw/ $wav"
#wav2raw +s -N  -d ${TMP_DIR}/raw/ $wav
csh wav2raw.sh -d ${TMP_DIR}/raw/ $wav

# Apply high pass filter (70Hz), choose the first channel only and conduct zero checking 
ch_wave -itype raw -f $inputrate -scale 0.95 -otype raw ${TMP_DIR}/raw/${base}.raw \
    | ch_wave -itype raw -f $inputrate -hpfilter 70 -forder 6001 -F $inputrate -otype raw \
    | x2x -o +sa\
    | awk 'BEGIN{long=0;value=0}((value==$1)&&(long>10)){long++}((value==$1)&&(long<=10)){print $1;long++}(value!=$1){long=0; value=$1 ; print $1}'\
    | x2x -o +as \
    > ${TMP_DIR}/raw/${base}.raw_orig

# Check the speech active level. If audio includes speech, conduct amplitude normalisation 
# If not, this does not output anything since they have silence or idle noise only 
sv56demo -log ${VAD_OUTPUT}/${base}.log -q -lev $level -sf $inputrate \
    ${TMP_DIR}/raw/${base}.raw_orig ${TMP_DIR}/raw/${base}.raw_norm 640

# Check if the amplitude normalisation created clipped waveform
if test -s ${VAD_OUTPUT}/${base}.log  
then
    if [ `grep -c "the dB level chosen causes SATURATION"  ${VAD_OUTPUT}/${base}.log` -eq 1 ]; 
    then
        echo "...${base}.wav was skipped due to SATURATION..."
        rm -f ${TMP_DIR}/raw/${base}.raw_norm 
        exit 0
    fi
else
    echo "VAD failed for ${base}.wav. Please check this audio file"
    exit 1 
fi

# Apply down-sampling or upsampling here if necessary
if test -s ${TMP_DIR}/raw/${base}.raw_norm
then
    case $rate in
        48000)
            case $inputrate in 
                8000) # upsample 8kHz to 48kzH
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | interpolate -p 2 -d \
                        | interpolate -p 2 -d \
                        | interpolate -p 2 -d \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs \
                        > ${TMP_DIR}/raw/${base}.${suffix} ;;
                11025) # upsample 11.025kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | interpolate -p 2 -d \
                        | interpolate -p 2 -d \
                        | us -s 34 \
                        | us -c ${LPF_PATH}/lpfcoef.3to5 -u 5 -d 3 \
                        | us -c ${LPF_PATH}/lpfcoef.7to8 -u 8 -d 7 \
                        | us -c ${LPF_PATH}/lpfcoef.7to4 -u 4 -d 7 \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs \
                        > ${TMP_DIR}/raw/${base}.${suffix} ;;
                16000) # upsample 16kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | interpolate -p 2 -d \
                        | interpolate -p 2 -d \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs \
                        > ${TMP_DIR}/raw/${base}.${suffix} ;;
                22050) # upsample 22.05kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | interpolate -p 2 -d \
                        | us -s 34 \
                        | us -c ${LPF_PATH}/lpfcoef.3to5 -u 5 -d 3 \
                        | us -c ${LPF_PATH}/lpfcoef.7to8 -u 8 -d 7 \
                        | us -c ${LPF_PATH}/lpfcoef.7to4 -u 4 -d 7 \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs > ${TMP_DIR}/raw/${base}.${suffix} ;;
                25000) # upsample 25kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | us -s 58 \
                        | us -s 57 \
                        | us -c ${LPF_PATH}/lpfcoef.7to4 -u 4 -d 7 \
                        | interpolate -p 2 -d \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs > ${TMP_DIR}/raw/${base}.${suffix} ;;
                32000) # upsample 32kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | interpolate -p 2 -d \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs \
                        > ${TMP_DIR}/raw/${base}.${suffix} ;;
                44100) # upsample 44.1kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | us -s 34 \
                        | us -c ${LPF_PATH}/lpfcoef.3to5 -u 5 -d 3 \
                        | us -c ${LPF_PATH}/lpfcoef.7to8 -u 8 -d 7 \
                        | us -c ${LPF_PATH}/lpfcoef.7to4 -u 4 -d 7 \
                        | ds -s 43 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs > ${TMP_DIR}/raw/${base}.${suffix} ;;
                48000) # Just copy 
                    mv  ${TMP_DIR}/raw/${base}.raw_norm ${TMP_DIR}/raw/${base}.${suffix} ;;
                96000) # downsample 96kHz to 48kHz
                    x2x -o +sf ${TMP_DIR}/raw/${base}.raw_norm \
                        | ds -s 21 \
                        | sopr -f -32767 \
                        | sopr -c 32767 \
                        | x2x -o +fs \
                        > ${TMP_DIR}/raw/${base}.${suffix} ;;
                *)
                    ch_wave -itype raw -f $inputrate -otype raw -F $rate \
                        ${TMP_DIR}/raw/${base}.raw_norm -o ${TMP_DIR}/raw/${base}.${suffix} ;;
            esac ;;
        *) # if target sampling frequency is not 48kHz, use ch_wav for sampling frequency conversion (this is lazy implementation!)
            ch_wave -itype raw -f $inputrate -otype raw -F $rate \
                ${TMP_DIR}/raw/${base}.raw_norm -o ${TMP_DIR}/raw/${base}.${suffix} ;;
    esac
    
    # Get activity factor
    activity=`grep "Activity factor" ${VAD_OUTPUT}/${base}.log | awk '{print $(NF-1)"/100"}' | bc -l | awk '{printf "%.2f\n", $1}'`
    # Compute log-energy profile (dB)
    shiftpoint=`echo "$rate * $shift / 1000" | bc -l | awk '{printf "%d\n", $1}'` # e.g. Frame shift in point (80 = 16000 * 0.005)
    windowpoint=`echo "$rate * $windur / 1000" | bc -l | awk '{printf "%d\n", $1}'` # e.g. Window length in point (400 = 16000 * 0.025)
    x2x -o +sf ${TMP_DIR}/raw/${base}.${suffix} \
        | frame -l $windowpoint -p $shiftpoint \
        | acorr -m 0 -l $windowpoint \
        | sopr -f 0.1 -LOG10 -m 10 \
        > ${TMP_DIR}/vad/${base}.nrg
    # Average level (dB)
    meanlev=`average ${TMP_DIR}/vad/${base}.nrg | x2x -o +fa`
    # Voice activity threshold
    vad_thres=`echo "scale=5;$meanlev - 10*l($activity)/l(10)" | bc -l | awk '{printf "%.2f\n", $1}'`
    # Voice activity detection
    x2x -o +fa ${TMP_DIR}/vad/${base}.nrg \
        | awk 'BEGIN{thres='$vad_thres';shift='$shift'}{if ($1 > thres) print NR*shift/1000}' \
        > ${TMP_DIR}/vad/${base}.vad

    speechstarttime=`head -1 ${TMP_DIR}/vad/${base}.vad`
    speechendtime=`tail -1 ${TMP_DIR}/vad/${base}.vad`    

    fileend=`ch_wave -info -f $rate -itype raw ${TMP_DIR}/raw/${base}.${suffix} | grep "Duration" | awk '{print $NF}'`
    silenceend=`echo "$fileend - $speechendtime" | bc -l | awk '{printf "%.2f\n", $1}'`
    
    trimcommands=" "
    trimcommande=" "
    
    # Judge if silence in the beginnning of audio file is too long or not 
    isSilenceLong=`echo "$speechstarttime > $silleng" | bc -l | awk '{printf "%d\n", $1}'`
    if [ $isSilenceLong -eq 1 ] 
    then 
        trimstart=`echo "$speechstarttime - $silleng" | bc -l | awk '{printf "%.2f\n", $1}'` 
        trimcommands=" -start $trimstart " 
    fi 
    
    # Judge if silence in the end of audio file is too long or not  
    isSilenceLong=`echo "$silenceend > $silleng" | bc -l | awk '{printf "%d\n", $1}'`
    if [ $isSilenceLong -eq 1 ]         
    then 
        trimend=`echo "$speechendtime + $silleng" | bc -l | awk '{printf "%.2f\n", $1}'` 
        trimcommande=" -end $trimend"
    fi 
    
     # Discard audio files that have too short silence 
    isSSilenceShort=`echo "$speechstarttime < $minsil" | bc -l | awk '{printf "%d\n", $1}'`
    isESilenceShort=`echo "$silenceend < $minsil" | bc -l | awk '{printf "%d\n", $1}'`
    
#    if [ $isSSilenceShort -eq 0 -a $isESilenceShort -eq 0 ]
#    then  
        # Trim silences
        ch_wave $trimcommands $trimcommande -c 0 -f $rate -F $rate -itype raw \
            -otype raw ${TMP_DIR}/raw/${base}.${suffix} -o ${RAW_OUTPUT}/${base}.raw 
#    else 
#        echo "...${base}.wav was discarded due to short silence lengths..."
#        exit 0
#    fi

    
    if test -s ${RAW_OUTPUT}/${base}.raw 
    then
        krate=`echo "$rate / 1000" | bc -l | awk '{printf "%.3f\n", $1}'`
        #echo "...Extract acoustic features..."
        # estimate F0 using get_f0 using 1ms just for seting F0 ranges 
        tmpshiftpoint=`echo "$rate / 1000" | bc -l | awk '{printf "%d\n", $1}'` # e.g. Frame shift in point (80 = 16000 * 0.001)
        x2x -o +sf ${RAW_OUTPUT}/${base}.raw \
            | pitch -a 0 -s $krate -p $tmpshiftpoint -t $vuvthresh -L $minf0 -H $maxf0 -o 1 \
            | x2x -o +fa \
            > ${F0_OUTPUT}/${base}.f0 
        
        awk '$1!=0{print log($1)}' ${F0_OUTPUT}/${base}.f0 > ${TMP_DIR}/cmp/${base}.f0test
        # Ignore utterances which do not have any voiced frames
        if test -s ${TMP_DIR}/cmp/${base}.f0test
        then
            mean=`x2x +af ${TMP_DIR}/cmp/${base}.f0test | vstat -o 1 | x2x +fa`
            std=`x2x +af ${TMP_DIR}/cmp/${base}.f0test | vstat -o 2 | sopr -R | x2x +fa`
            newmaxf0=`echo "scale=5;$mean + $outlier * $std" | bc | x2x +af | sopr -EXP | x2x +fa | awk '{printf "%d\n",$1+0.5}'`
            newminf0=`echo "scale=5;$mean - $outlier * $std" | bc | x2x +af | sopr -EXP | x2x +fa | awk '{printf "%d\n",$1+0.5}'`
            #echo $newmaxf0 $newminf0
        else
            newmaxf0=480
            newminf0=55
        fi
        rm -f ${TMP_DIR}/cmp/${base}.f0test
        rm -f ${F0_OUTPUT}/${base}.f0 

        # estimate F0 using get_f0 based on new F0 ranges 
        x2x -o +sf ${RAW_OUTPUT}/${base}.raw \
            | pitch -a 0 -s $krate -p $shiftpoint -t $vuvthresh -L $newminf0 -H $newmaxf0 -o 1 \
            | x2x -o +fa \
            > ${TMP_DIR}/cmp/${base}.f0 

        #echo "Moving median filter" 
        x2x +af ${TMP_DIR}/cmp/${base}.f0 \
            | delay -s 1 -f \
            | x2x +fa \
            > ${TMP_DIR}/cmp/${base}.f0.delay
        echo "0.000000" \
            > ${TMP_DIR}/cmp/${base}.f0.zero
        x2x +af ${TMP_DIR}/cmp/${base}.f0 \
            | bcut +f -s 1 \
            | x2x +fa \
            | cat - ${TMP_DIR}/cmp/${base}.f0.zero \
            > ${TMP_DIR}/cmp/${base}.f0.shift 
        paste ${TMP_DIR}/cmp/${base}.f0.delay ${TMP_DIR}/cmp/${base}.f0 ${TMP_DIR}/cmp/${base}.f0.shift \
            | awk -f ${TMP_DIR}/max.awk \
            > ${TMP_DIR}/cmp/${base}.f0.median

        rm -f ${TMP_DIR}/cmp/${base}.f0.delay ${TMP_DIR}/cmp/${base}.f0.shift 
        #echo "Moving mean (linear) filter"
        x2x +af ${TMP_DIR}/cmp/${base}.f0.median \
            | delay -s 1 -f \
            | x2x +fa \
            > ${TMP_DIR}/cmp/${base}.f0.delay
        x2x +af ${TMP_DIR}/cmp/${base}.f0.median \
            | bcut +f -s 1 \
            | x2x +fa \
            | cat - ${TMP_DIR}/cmp/${base}.f0.zero \
            > ${TMP_DIR}/cmp/${base}.f0.shift
        paste ${TMP_DIR}/cmp/${base}.f0.delay ${TMP_DIR}/cmp/${base}.f0.median ${TMP_DIR}/cmp/${base}.f0.shift \
            | awk -f ${TMP_DIR}/smooth.awk \
            > ${F0_OUTPUT}/${base}.f0

        # Transform F0 to auditory scales 
        case $f0scale in 
            "Log") # Log
                awk '$1!=0{print log($1)}$1==0{print}' ${F0_OUTPUT}/${base}.f0 \
                    | x2x -o +af \
                    > ${F0_OUTPUT}/${base}.lf0 ;; 
            "Mel") # Mel
                awk '$1!=0{print 1127*log(1+$1/700)}$1==0{print}' ${F0_OUTPUT}/${base}.f0 \
                    | x2x -o +af \
                    > ${F0_OUTPUT}/${base}.lf0 ;; 
            "ERB") # ERB (Simplified formula by Glasberg & Moore in 1990)
                awk '$1!=0{print 21.4 * log(0.00437 * $1 + 1)/log(10)}$1==0{print}' ${F0_OUTPUT}/${base}.f0 \
                    | x2x -o +af \
                    > ${F0_OUTPUT}/${base}.lf0 ;; 
        esac
        
        # Ignore utterances which consist of only unvoiced frames
        awk '$1!=0{print $1}' ${F0_OUTPUT}/${base}.f0 > ${TMP_DIR}/cmp/${base}.f0test
        if test -s ${TMP_DIR}/cmp/${base}.f0test
        then
            # Aperiodic energy analysis
            straight_bndap -nmsg -bndap -float -f $rate -shift $shift -f0shift $shift -f0file ${F0_OUTPUT}/${base}.f0 \
                -fftl $fftlen -apord $apord -raw ${RAW_OUTPUT}/${base}.raw ${BAP_OUTPUT}/${base}.bndap & 
            
            # STRAIGHT Spectral Analysis"
            straight_mcep -nmsg -f $rate -fftl $fftlen -apord $apord -shift $shift -f0shift $shift -order $order \
                -f0file ${F0_OUTPUT}/${base}.f0 -pow -float -raw ${RAW_OUTPUT}/${base}.raw ${MCEP_OUTPUT}/${base}.spec
            
            # Calculate alpha using equations introduced by Julius Smith
            # "Bark and ERB Bilinear transforms IEEE Speech & Audio Proc
            # Vol.7 No.6 Nov. 1999
            case $specscale in 
                "Bark") # Bark 
                    alpha=`echo "0.8517 * sqrt ( a ( 0.06583 * $krate )) - 0.1916" | bc -l | awk '{printf "%.2f", $1}'` ;;
                "ERB") # ERB 
                    alpha=`echo " 0.5941 * sqrt ( a ( 0.1418 * $krate )) + 0.03237 " | bc -l | awk '{printf "%.2f", $1}'` ;;
            esac
            
            case $spectype in 
                "MCEP") # Convert STRAIGHT spectrum to mel-cepstrum
                    mcep -a $alpha -m $order -l $fftlen -e 1.0E-8 -j 0 -f 0.0 -q 3 ${MCEP_OUTPUT}/${base}.spec \
                        > ${MCEP_OUTPUT}/${base}.mcep ;;
                "MGC") # Convert STRAIGHT spectrum to mel-cepstrum via mel-generalized cepstral analysis"
                    mgcep -a $alpha -c $mgcgamma -m $order -l $fftlen -e 1.0E-8 -j 0 -f 0.0 -q 3 ${MCEP_OUTPUT}/${base}.spec \
                        | mgc2mgc -a $alpha -c $mgcgamma -m $order -A $alpha -G 0 -M $order \
                        > ${MCEP_OUTPUT}/${base}.mcep ;;
                "MELLSP") # Convert STRAIGHT spectrum to mel-LSP
                    mgcep -a $alpha -c 1 -m $order -l $fftlen -e 1.0E-8 -j 0 -f 0.0 -q 3 -o 4 ${MCEP_OUTPUT}/${base}.spec \
                        | lpc2lsp -m $order -s $krate -n 1024 -p 8 -d 1e-8 -l \
                        > ${MCEP_OUTPUT}/${base}.mcep ;;
                "MGCLSP") # Convert STRAIGHT spectrum to MGC-LSP
                    mgcep -a $alpha -c $mgcgamma -m $order -l $fftlen -e 1.0E-8 -j 0 -f 0.0 -q 3 -o 4 ${MCEP_OUTPUT}/${base}.spec \
                        | lpc2lsp -m $order -s $krate -n 1024 -p 8 -d 1e-8 -l \
                        > ${MCEP_OUTPUT}/${base}.mcep ;;
            esac
            rm -rf ${MCEP_OUTPUT}/${base}.spec
            wait
        else
            echo "...${base}.wav was skipped because all frames are unvoiced..."
            exit 0
        fi
    fi
fi

#echo "...Calculate Delta..."
# need to check if files exists or not 
if  test -s ${HTS_OUTPUT}/mcep_d1.win \
    && test -s ${HTS_OUTPUT}/logF0_d1.win \
    && test -s ${HTS_OUTPUT}/bndap_d1.win \
    && test -s ${HTS_OUTPUT}/mcep_d2.win \
    && test -s ${HTS_OUTPUT}/logF0_d2.win \
    && test -s ${HTS_OUTPUT}/bndap_d2.win
then
    #echo "...Use existing delta window..."
    winstatus=1
else
    calcwin -l $winlength > ${HTS_OUTPUT}/mcep_d1.win
    calcwin -l $winlength > ${HTS_OUTPUT}/logF0_d1.win
    calcwin -l $winlength > ${HTS_OUTPUT}/bndap_d1.win
    calcwin -l $winlength -a > ${HTS_OUTPUT}/mcep_d2.win
    calcwin -l $winlength -a > ${HTS_OUTPUT}/logF0_d2.win
    calcwin -l $winlength -a > ${HTS_OUTPUT}/bndap_d2.win
fi
byte=`echo "(($order + 1) * 3 + 3 + $baporder * 3 ) * 4" | bc -l | awk '{printf "%d\n", $1}'`
gvbyte=`echo "(($order + 1)  + 1 + $baporder ) * 4" | bc -l | awk '{printf "%d\n", $1}'`
bdim=`echo "$baporder - 1" | bc -l | awk '{printf "%d\n", $1}'`

if test -s ${MCEP_OUTPUT}/${base}.mcep \
    && test -s ${F0_OUTPUT}/${base}.lf0 \
    && test -s ${BAP_OUTPUT}/${base}.bndap
then
    cmpdat -m $order -n $bdim \
        -c ${HTS_OUTPUT}/mcep_d1.win -c ${HTS_OUTPUT}/mcep_d2.win \
        -p ${HTS_OUTPUT}/logF0_d1.win -p ${HTS_OUTPUT}/logF0_d2.win \
        -b ${HTS_OUTPUT}/bndap_d1.win -b ${HTS_OUTPUT}/bndap_d2.win \
        ${MCEP_OUTPUT}/${base}.mcep \
        ${F0_OUTPUT}/${base}.lf0 \
        ${BAP_OUTPUT}/${base}.bndap \
        > ${CMP_OUTPUT}/${base}.cmp

    # check if the file has illegal values such as NaN or not
    nan ${CMP_OUTPUT}/${base}.cmp > ${TMP_DIR}/cmp/${base}.nan
    if test -s ${TMP_DIR}/cmp/${base}.nan
    then
        rm -f ${CMP_OUTPUT}/${base}.cmp
        echo "Acoustic features for ${base}.wav seem to be invalid."
    else 
        Hhead -p $shift -s $byte -k 9 -o ${CMP_OUTPUT}/${base}.cmp

        #Calculate GV of each file
        vstat -n $order    -o 2 -d ${MCEP_OUTPUT}/${base}.mcep > ${TMP_DIR}/gv/${base}.gv.mcep
        vstat -l $baporder -o 2 -d ${BAP_OUTPUT}/${base}.bndap > ${TMP_DIR}/gv/${base}.gv.bndap
        x2x -o +fa ${F0_OUTPUT}/${base}.lf0 \
            | awk '$1!=0{print $1}' \
            | x2x -o +af \
            | vstat -l 1 -o 2 -d \
            > ${TMP_DIR}/gv/${base}.gv.lf0

        #Combile GV files 
        cat ${TMP_DIR}/gv/${base}.gv.mcep  ${TMP_DIR}/gv/${base}.gv.lf0 ${TMP_DIR}/gv/${base}.gv.bndap \
            > ${GV_OUTPUT}/${base}.cmp

        # check if the file has illegal values such as NaN or not
        nan ${GV_OUTPUT}/${base}.cmp > ${TMP_DIR}/gv/${base}.nan
        if test -s ${TMP_DIR}/gv/${base}.nan
        then
            rm -f ${GV_OUTPUT}/${base}.cmp
            rm -f ${TMP_DIR}/gv/${base}.gv.mcep ${TMP_DIR}/gv/${base}.gv.lf0 ${TMP_DIR}/gv/${base}.gv.bndap
            echo "GV features for ${base}.wav seem to be invalid."
        else 
            Hhead -p $shift -s $gvbyte -k 9 -o ${GV_OUTPUT}/${base}.cmp
        fi
    fi
else 
    echo "Acoustic features cannot be extracted from ${base}.wav Please check this audio file"
    exit 1
fi

# Analysis-by-synthesis
if [ $abs -eq 1 ]
then
    if test -s ${MCEP_OUTPUT}/${base}.mcep \
        && test -s ${F0_OUTPUT}/${base}.f0 \
        && test -s ${BAP_OUTPUT}/${base}.bndap
    then

    # Convert given mel-cepstrum or LSP to the smoothed spectrum
    case $spectype in 
        "MCEP") # Convert STRAIGHT spectrum to mel-cepstrum
            mgc2sp -a $alpha -g 0 -m $order -l $fftlen -o 2 ${MCEP_OUTPUT}/${base}.mcep \
                | x2x +fd \
                > ${TMP_DIR}/abs/${base}.spec.double ;;
        "MGC") # Convert STRAIGHT spectrum to mel-cepstrum via mel-generalized cepstral analysis"
            mgc2sp -a $alpha -g 0 -m $order -l $fftlen -o 2 ${MCEP_OUTPUT}/${base}.mcep \
                | x2x +fd \
                > ${TMP_DIR}/abs/${base}.spec.double ;;
        "MELLSP") # Convert STRAIGHT spectrum to mel-LSP
            lspcheck -m $order -s $krate -r 0.01 ${MCEP_OUTPUT}/${base}.mcep \
                | lsp2lpc -m $order -s $krate -l \
                | mgc2mgc -a $alpha -c 1 -m $order -n -u -A $alpha -C 1 -M $order \
                | mgc2sp -a $alpha -c 1 -m $order -l $fftlen -o 2 \
                | x2x +fd \
                > ${TMP_DIR}/abs/${base}.spec.double  ;;
        "MGCLSP") # Convert STRAIGHT spectrum to MGC-LSP
            lspcheck -m $order -s $krate -r 0.01 ${MCEP_OUTPUT}/${base}.mcep \
                | lsp2lpc -m $order -s $krate -l \
                | mgc2mgc -a $alpha -c $mgcgamma -m $order -n -u -A $alpha -C $mgcgamma -M $order \
                | mgc2sp -a $alpha -c $mgcgamma -m $order -l $fftlen -o 2 \
                | x2x +fd \
                > ${TMP_DIR}/abs/${base}.spec.double ;;
    esac
    
    x2x +fd ${BAP_OUTPUT}/${base}.bndap  > ${TMP_DIR}/abs/${base}.bndap.double

    # Copy synthesis using smoothed spectrum obtained from mel-cepstrum or MGC-LSP and band-limited aperiodicity
    synthesis_fft \
        -f $rate \
        -spec \
        -fftl $fftlen \
        -order $order \
        -shift $shift \
        -sigp 1.2 \
        -cornf 4000 \
        -bap \
        -apfile ${TMP_DIR}/abs/${base}.bndap.double \
        ${F0_OUTPUT}/${base}.f0 \
        ${TMP_DIR}/abs/${base}.spec.double \
        ${TMP_DIR}/abs/${base}.wav \
        > ${TMP_DIR}/abs/${base}.log

    else 
        echo "Synthetic speech cannot be generated from ${base}.wav Please check this audio file"
        exit 1
    fi
fi

exit 0 

