#!/system/bin/sh
#
# Version: 1.3
#     by zyhk

MYDIR=${0%/*}

# Check whether this script has been marked "disable", or not
  if [ ! -d "$MYDIR" ]; then
    echo "cannot get the current directory!" 1>&2 ; 
    exit 1
  elif [ -e "$MYDIR/disable" ] ; then
    echo "this script is now disabled!" 1>&2 ; 
    exit 0
  fi
 # End
 
# Help message
  offloadMode="false"
  resetMode="false"
  if [ $# -gt 0 ]; then
     case "$1" in
       "-o" | "--offload" )
         offloadMode="true"
         shift
         ;;
       "-o2" | "--offload2" )
         offloadMode="alternate"
         shift
         ;;
       "-b" | "--bypass-offload" )
         offloadMode="bypass"
         shift
         ;;
       "-r" | "--reset" )
         resetMode="true"
         shift
         ;;
       "-h" | "--help" | -* )
         echo "Usage: ${0##*/} [--reset][--offload][--bypass-offload] [[44k|48k|88k|96k|176k|192k|353k|384k|706k|768k] [[16|24|32]]]" 1>&2
         echo "  Note: ${0##*/} requires to unlock the USB audio class driver's limitation (upto 96kHz lock or 384kHz offload lock)" 1>&2
         echo "           if you specify greater than 96kHz or 384kHz (in case of offload)" 1>&2
         exit 0
         ;;
     esac
  fi
# End of help message

  function reloadAudioServers() 
  {
    setprop ctl.restart audioserver
    if [ $# -gt 0  -a  "$1" = "all" ]; then
      audioHal="$(getprop |sed -nE 's/.*init\.svc\.(.*audio-hal[^]]*).*/\1/p')"
      setprop ctl.restart "$audioHal" 1>"/dev/null" 2>&1
      setprop ctl.restart vendor.audio-hal-2-0 1>"/dev/null" 2>&1
      setprop ctl.restart audio-hal-2-0 1>"/dev/null" 2>&1
    fi
  }
 
# Reset
  if "$resetMode"; then
    for i in "/vendor/etc/audio_policy_configuration.xml" "/vendor/etc/audio/audio_policy_configuration.xml" \
  	  "/vendor/etc/usb_audio_policy_configuration.xml" "/system/etc/usb_audio_policy_configuration.xml"; do
       if [ -r "$i" ]; then
          umount "$i" 1>"/dev/null" 2>&1
       fi
    done
    if [ "`getprop init.svc.audioserver`" = "running" ]; then
      reloadAudioServers "all"
    fi
    exit 0
  fi
# Reset End
 
# Set parameters
  sRate="44100"
  bDepth="32"

  case $# in
    0 ) ;;
    1 )  sRate="$1";;
    2 )  sRate="$1"; bDepth="$2";;
    * )  echo "too many arguments (n=$#)!" 1>&2 ; exit 1;;
  esac
# End of setting parameters

# Normalize arguments
  case "$sRate" in
    "44k" | "44.1k" )
      sRate="44100"
      ;;
    "48k" )
      sRate="48000"
      ;;
    "88k" | "88.2k" )
      sRate="88200"
      ;;
    "96k" )
      sRate="96000"
      ;;
    "176k" | "176.4k" )
      sRate="176400"
      ;;
    "192k" )
      sRate="192000"
      ;;
    "352k" | "353k" | "352.8k" )
      sRate="352800"
      ;;
    "384k" )
      sRate="384000"
      ;;
    "705k" | "706k" | "705.6k" )
      sRate="705600"
      ;;
    "768k" )
      sRate="768000"
      ;;
     * )
      if expr "$sRate" : "[1-9][0-9]*$" 1>"/dev/null" 2>&1; then
          if [ $sRate -lt 44100  -o  $sRate -gt 768000 ]; then
            echo "unsupported sample rate (rate=$sRate)!" 1>&2 
            exit 1
          fi
      else
          echo "unsupported sample rate (rate=$sRate)!" 1>&2 
          exit 1
      fi
      ;;
  esac

  if [ ! "$offloadMode" = "true"  -a  $sRate -gt 96000 ]; then
    echo "    Warning: ${0##*/} requires to unlock the USB audio class driver's limitation (upto 96kHz lock)" 1>&2
  elif [ "$offloadMode" = "true"  -a  $sRate -gt 384000 ]; then
    echo "    Warning: ${0##*/} requires to unlock the USB audio hardware offload driver's limitation (upto 384kHz lock)" 1>&2
  fi

  aFormat="AUDIO_FORMAT_PCM_32_BIT"
  case "$bDepth" in
    16 )
      aFormat="AUDIO_FORMAT_PCM_16_BIT"
      ;;
    24 )
      aFormat="AUDIO_FORMAT_PCM_24_BIT_PACKED"
      ;;
    32 )
      aFormat="AUDIO_FORMAT_PCM_32_BIT"
      ;;
    * )
      echo "unknow bit depth specified (depth=$bDepth)!" 1>&2
      exit 1
      ;;
  esac
# End of argument normalization

# Overlay a generated {usb} audio policy configuration file on "/vendor/etc/{usb_}audio_policy_configuration.xml"
  genfile="/data/local/tmp/usb_conf_generated.xml"
  case "$offloadMode" in
    "true" )
       template="$MYDIR/templates/usb_conf_offload_template.xml"
       overlayTarget="/vendor/etc/audio_policy_configuration.xml"
       ;;
    "alternate" )
       template="$MYDIR/templates/usb_conf_offload_template_2.xml"
       overlayTarget="/vendor/etc/audio_policy_configuration.xml"
       ;;
    "bypass" )
       template="$MYDIR/templates/usb_conf_bypass_offload_template.xml"
       overlayTarget="/vendor/etc/audio_policy_configuration.xml"
        ;;
    "false" )
       template="$MYDIR/templates/usb_conf_template.xml"
       overlayTarget="/vendor/etc/usb_audio_policy_configuration.xml"
       ;;
  esac

  if [ -r "$template" ]; then
    if [ -e "$genfile" ]; then
      rm -f "$genfile"
    fi
    sed -e "s/%SAMPLING_RATE%/$sRate/g" -e "s/%AUDIO_FORMAT%/$aFormat/g" "$template" >"$genfile"
    if [ $? -eq 0 ]; then
      chmod 644 "$genfile"
      if [ -r "$overlayTarget" ]; then
        umount "$overlayTarget" 1>"/dev/null" 2>&1
        mount -o bind "$genfile" "$overlayTarget"
        if [ $? -gt 0 ]; then
          echo "overlaying a generated USB configuration XML file failed!" 1>&2 
          exit 1
        fi
      else
        echo "overlaying target (\"$overlayTarget\") doesn't exist!" 1>&2 
        exit 1
      fi
      if [ "$overlayTarget" = "/vendor/etc/audio_policy_configuration.xml"  -a  -r "/vendor/etc/audio/audio_policy_configuration.xml" ]; then
        umount "/vendor/etc/audio/audio_policy_configuration.xml" 1>"/dev/null" 2>&1
        mount -o bind "$genfile" "/vendor/etc/audio/audio_policy_configuration.xml"
      fi
      if [ "$overlayTarget" = "/vendor/etc/usb_audio_policy_configuration.xml"  -a  -r "/system/etc/usb_audio_policy_configuration.xml" ]; then
        umount "/system/etc/usb_audio_policy_configuration.xml" 1>"/dev/null" 2>&1
        mount -o bind "$genfile" "/system/etc/usb_audio_policy_configuration.xml"
      fi
    else
      echo "audio policy XML file genaration failed!" 1>&2 
      exit 1
    fi
  else
    echo "a template USB configuration file not found!" 1>&2 
    exit 1
  fi
# End of overlay system files

# Reload audio policy configuration files.  
  if [ "`getprop init.svc.audioserver`" = "running" ]; then
    if [ "`getenforce`" = "Enforcing" ]; then
      setenforce 0
      reloadAudioServers
      # waiting for the audioserve reload completion during selnux permissive mode to avoid audio routing issues
      sleep 4
      setenforce 1
    else
      reloadAudioServers
    fi
    exit 0
  else
    echo "audioserver is not running!" 1>&2 
    exit 1
  fi
# End of reload
