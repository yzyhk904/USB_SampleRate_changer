#!/system/bin/sh
#
# My mock cheap in-DAC N-fold Over-sampling filer (fast roll-off type) of which quality level is set to be comparable to that of SoX HQ linear phase
#
# Try to use this from 44.1kHz to 706kHz (16x) or 354kHz (8x) up-sampling for comparing difference between mock series and 179dB_408_100.
#

MODDIR=${0%/*/*/*}
su -c "/system/bin/sh ${MODDIR}/extras/change-resampling-quality.sh --cheat 98 80 99"
