#!/system/bin/sh

MODDIR=${0%/*/*}
exec su -c "/system/bin/sh ${MODDIR}/extras/change-resampling-quality.sh 194 520 100"
