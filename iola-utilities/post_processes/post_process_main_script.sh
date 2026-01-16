##---------------------- created by Srinivas NY -----------------------
#-----------------------grib1 to netcdf by using cdo and ncl----------------------------------------#
#---------------------- File was created by the Srinivas NY ----------------------------------------#
#-----------------------wrfout from nmm model to grib1 by UPP --------------------------------------#
#------------------ it needed  1. wrf_cntrl.parm 2. Running ksh script in this folder --------------# 
#Run by "sh post_process_main_script.sh date upp_script_name (ex.sh --202305230000 run_unipost_frames)---#
#######  #####
export TOP_DIR=/scratch/RAJITH/WSM6/ysu/2025083000
export DOMAINPATH=${TOP_DIR}
export WRFPATH=/home/centos/model_build/iola_build/IOLA_repository/sorc/WRFV3
export UNIPOST_HOME=/home/centos/model_build/iola_build/IOLA_repository/sorc/UPP
export POSTEXEC=${UNIPOST_HOME}/bin
export SCRIPTS=${UNIPOST_HOME}/scripts
export modelDataPath=${TOP_DIR}        # or nemsprd
export paramFile=/scratch/IOLA_DATA/IOLA_OUTPUT/postprocessing_scripts/my_scripts/wrf_cntrl.parm_main  # or nmb_cntrl.parm
#export xmlCntrlFile=${DOMAINPATH}/postprd/parm/postcntrl.xml # for grib2
export dyncore="NMM"
export inFormat="netcdf"
export outFormat="grib"
#############################
export startdate=$1
export fhr=00
export lastfhr=24
export incrementhr=01
export startmin=0
export incrementmin=30
export lastmin=59
###############################
export domain_list="d03"
export copygb_opt="lat-lon"
export RUN_COMMAND="${POSTEXEC}/unipost.exe"
##### no need to change ####
export tmmark=tm00
export MP_SHARED_MEMORY=yes
export MP_LABELIO=yes
######### CHNAGE THE RUN script for frames or muinutes #####
mkdir ${DOMAINPATH}/postprd
cp $2 ${DOMAINPATH}/postprd ###change script by user selection
mkdir ${DOMAINPATH}/postprd/parm

##--------------selct  suitbale script based on your requirment -------------------------------------------------------#
#--run_unipost_frames:         WRFOUT present at all timeperiods in single file and hourly or morethan taht interval---#
#--run_unipost_frames_minutes: WRFOUT present at all timeperiods in single file and half-hourly interval---------------#
#--run_unipost:                WRFOUT present at one timeperiods at one file and hourly or morethan taht interval------#
#--run_unipost_minutes:        WRFOUT present at all timeperiods in single file and half-hourly interval---------------#
############################################
./$2
