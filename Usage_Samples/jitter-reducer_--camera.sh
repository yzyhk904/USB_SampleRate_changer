#!/system/bin/sh

MODDIR=${0%/*/*}
exec su -c "/system/bin/sh ${MODDIR}/extras/jitter-reducer.sh --camera --status"
