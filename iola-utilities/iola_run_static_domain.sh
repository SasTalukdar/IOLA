#!/bin/sh
#!/bin/bash
########################################################
##  THIS SCRIPT IS TO RUN IOLA-Atmosphere model########
## Prepared by Srinivas NY ##################
## sh iola_run_loop_by_srinu.sh date (ex. 2025032200) ##
########################################################
##set -x
ndateExe=/home/centos/model_build/iola_build/IOLA_repository/sorc/hwrf-utilities/exec/ndate.exe
if (! test -f "$ndateExe") then
    echo "Error: No ndate EXE was found for year $YY."
    echo "FIRST FIX IT: $ndateExe"
    exit 4
fi
#------------------------date and exp name------------------------#
export INITIAL_DATE=$1
export FCST_LENGTH=30
export EXPT=thunderstorm
export FINAL_DATE=`$ndateExe ${FCST_LENGTH} $INITIAL_DATE`
export FCST_RANGE=$FCST_LENGTH    # Forecast length 6, 12, 24,etc

#------------------------set paths ----------------------
export HOME_DIR=/home/centos/model_build/iola_build/IOLA_repository
export WPS_DIR=$HOME_DIR/sorc/WPSV3
export WRF_DIR=$HOME_DIR/sorc/WRFV3
export PARM_DIR=$HOME_DIR/parm
export IOLA_INPUT=/home/centos/model_build/INPUT_DATA
export FIX=${IOLA_INPUT}/fix
export OUTPUT=/home/centos/model_build/iola_build/IOLA_OUTPUT
export WORK_DIR=${OUTPUT}/${EXPT}

#####   WPS INPUT DATA PATH HERE ##############
export GFS_INPUT_DIR=${IOLA_INPUT}/GFS/${INITIAL_DATE}
export WPS_GEOG_DIR=${IOLA_INPUT}/fix/hwrf_wps_geo
#---------------------------------------------
export RUN_WPS=true
export RUN_REAL=true
export GFS_download=false
#----------------------------------------------
#----------------Namelist variables of WRF and WRF-Var----------------------------------
export OUTPUT_FREQ_MOAD=180
export OUTPUT_FREQ_INTER=60
export OUTPUT_FREQ_FINER=30
export TIME_STEP=10
export INTERVAL_SECONDS=10800
export E_VERT=75
export MP_PHYSICS=5
export PBL_PHY=3                    # 1-YSU sch.(SFC_LAY=1), 2-MYJ sch.(SFC_LAY=2)
export SFC_LAY=88                   # 1-Monin-Obukhov, 2-Monin-Obukhov Janjic eta sch.
export SFC_PHY=2                    # 1-Thermal Diffusion, 2-Noah
export CU_PHY=4                     # 1-KF, 2-BMJ, 3-GD, 99-Prev. KF
export URBAN_PHY=0
export NUM_SOIL_LAY=4               # 5-Thermal Diff(SFC_PHY=1), 4-Noah(SFC_PHY=2)
export DUMMY=1
#--------------------------------------------------------------------------------------
Clat=(20.2)
Clon=(85.8)
d2_lat_dia=(10.0 12.0 12.0 12.0 6.0)
d2_lon_dia=(10.0 12.0 12.0 12.0 6.0)
d3_lat_dia=(6.0 6.0 6.0 6.0 4.0)
d3_lon_dia=(6.0 6.0 6.0 6.0 4.0)

long_conv=0.5  # Longitude conversion factor
res_d1=0.06
MOAD_lat_size=32.0 # along lat D01 size
MOAD_lon_size=32.0  # along lon D01 size
grid_ratio=3
Slat=10     ### D01 starting lat
Slon=65        ## D01 starting lon
export REF_LAT=26.0
export REF_LON=81.0

####--------------For assimilatio ##################################
export NUM_CYC=1                    # how many times run
export CYCLE_PERIOD=12                # Assimilation cyclic frequence 06 12 24hrly
export WINDOW_RANGE=3                 # For obsproc time window

###################################################################
##### GFS data download Here ################
#if $GFS_download; then
#export wget_dir=https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod
#export cdate=$(echo $INITIAL_DATE | cut -c1-8)
#
#mkdir -p ${GFS_INPUT_DIR}/${INITIAL_DATE}
#####cd ${INITIAL_DATE}
#
#i=0
#while [ $i -le 12 ]; do
# hr=$(printf "%03d" "$i")
# echo "$hr"
# wget ${wget_dir}/gfs.${cdate}/${shour}/atmos/gfs.t${shour}z.pgrb2.0p25.f${hr}
# mv gfs.t${shour}z.pgrb2.0p25.f${hr} ${GFS_INPUT_DIR}/${INITIAL_DATE}
# i=$(( $hr + 3 ))
#done
#fi
################# GFS data download done ####################

###################################################################
#+++++++++++ Almost all user sections have ended ---------------####
#+++++++++++ except for changes in the namelist, if needed. -----###
#------------No change below the line------------------------------#
####################################################################
make_even() {
    local num=$1
    if (( num % 2 != 0 )); then
        num=$((num + 1))
    fi
    echo $num
}                   ### this is for points should be in even
###### calulation of number of points to D1 ##########
we1=$(echo "$MOAD_lon_size * $long_conv / $res_d1" | bc -l)
we1_points=$(printf "%.0f" $we1)
sn1_points=$(printf "%.0f" $(echo "$MOAD_lat_size / $res_d1" | bc -l))
we1_points=$(make_even $we1_points)
sn1_points=$(make_even $sn1_points)
echo $we1_points
echo $sn1_points
#res_d2=$(echo "$res_d1 / $grid_ratio" | bc -l)
#res_d3=$(echo "$res_d2 / $grid_ratio" | bc -l)

res_d2=$(printf "%.3f" $(echo "$res_d1 / $grid_ratio" | bc -l))
res_d3=$(printf "%.3f" $(echo "$res_d2 / $grid_ratio" | bc -l))
echo $res_d2
echo $res_d3
###### calulation of number of points and i & j start for D2 and D3 ##########
namelist_we=()
namelist_sn=()
namelist_isrt=()
namelist_jsrt=()
namelist_resd=()
for ((i=0; i<${#Clat[@]}; i++)); do
    we2_points=$(printf "%.0f" $(echo "${d2_lon_dia[i]} * $long_conv / $res_d2" | bc -l))
    sn2_points=$(printf "%.0f" $(echo "${d2_lat_dia[i]} / $res_d2" | bc -l))
    we3_points=$(printf "%.0f" $(echo "${d3_lon_dia[i]} * $long_conv / $res_d3" | bc -l))
    sn3_points=$(printf "%.0f" $(echo "${d3_lat_dia[i]} / $res_d3" | bc -l))
    we2_points=$(make_even $we2_points)
    sn2_points=$(( $we2_points * 2 ))
    we3_points=$(make_even $we3_points)
    sn3_points=$(( $we3_points * 2 ))
#    we2_points=$(make_even $we2_points)
#    sn2_points=$(make_even $sn2_points)
#    we3_points=$(make_even $we3_points)
#    sn3_points=$(make_even $sn3_points)

    d2_slat=$(echo "${Clat[i]} - ${d2_lat_dia[i]} / 2" | bc -l)
    d2_lat_dist=$(echo "${d2_slat} - ${Slat} " | bc -l)
    real_jstart2=$(echo "$d2_lat_dist / $res_d1" | bc -l)
    d2_jstart=$(printf "%.0f" $real_jstart2)
    
    d3_lat_dist=$(echo "${d2_lat_dia[i]} / 2 - ${d3_lat_dia[i]} / 2" | bc -l)
    real_jstart3=$(echo "$d3_lat_dist / $res_d2" | bc -l)
    d3_jstart=$(printf "%.0f" $real_jstart3)

    d2_slon=$(echo "${Clon[i]} - ${d2_lon_dia[i]} / 2" | bc -l)
    d2_lon_dist=$(echo "${d2_slon} - ${Slon}" | bc -l)
    real_istart2=$(echo "$d2_lon_dist * $long_conv / $res_d1" | bc -l)
    d2_istart=$(printf "%.0f" $real_istart2)

    
    d3_lon_dist=$(echo "${d2_lon_dia[i]} / 2 - ${d3_lon_dia[i]} / 2" | bc -l)
    real_istart3=$(echo "$d3_lon_dist * $long_conv / $res_d2" | bc -l)
    d3_istart=$(printf "%.0f" $real_istart3)
    
    namelist_we+=("$we2_points" "$we3_points")
    namelist_sn+=("$sn2_points" "$sn3_points")
    namelist_isrt+=("$d2_istart" "$d3_istart")
    namelist_jsrt+=("$d2_jstart" "$d3_jstart")
    namelist_resd+=("$res_d2" "$res_d3")
done

export fyear=$(echo $FINAL_DATE | cut -c1-4)
export fmonth=$(echo $FINAL_DATE | cut -c5-6)
export fday=$(echo $FINAL_DATE | cut -c7-8)
export fhour=$(echo $FINAL_DATE | cut -c9-10)

export ncyc=0

while [ $((ncyc=ncyc+1)) -le $NUM_CYC ]
do
#-----------------------------------
export syear=$(echo $INITIAL_DATE | cut -c1-4)
export smonth=$(echo $INITIAL_DATE | cut -c5-6)
export sday=$(echo $INITIAL_DATE | cut -c7-8)
export shour=$(echo $INITIAL_DATE | cut -c9-10)

export START_DATE=$syear-$smonth'-'$sday'_'$shour
export END_DATE=$fyear-$fmonth'-'$fday'_'$fhour

max_length=$((${#namelist_we[@]} + 1)) ## +1 for MOAD ###
echo "${namelist_we[@]}"
echo $max_length

####chage date related #############
srt_date=$(printf "'$START_DATE:00:00', %.0s" $(seq 1 $max_length))
ed_date=$(printf "'$END_DATE:00:00', %.0s" $(seq 1 $max_length))
srt_year=$(printf "$syear, %.0s" $(seq 1 $max_length))
srt_mon=$(printf "$smonth, %.0s" $(seq 1 $max_length))
srt_day=$(printf "$sday, %.0s" $(seq 1 $max_length))
srt_hh=$(printf "$shour, %.0s" $(seq 1 $max_length))
fnl_year=$(printf "$fyear, %.0s" $(seq 1 $max_length))
fnl_mon=$(printf "$fmonth, %.0s" $(seq 1 $max_length))
fnl_day=$(printf "$fday, %.0s" $(seq 1 $max_length))
fnl_hh=$(printf "$fhour, %.0s" $(seq 1 $max_length))

##### change physics realted ###############
MP_PHYSICS1=$(printf "$MP_PHYSICS, %.0s" $(seq 1 $max_length))
E_VERT1=$(printf "$E_VERT, %.0s" $(seq 1 $max_length))
PBL_PHY1=$(printf "$PBL_PHY, %.0s" $(seq 1 $max_length))
SFC_LAY1=$(printf "$SFC_LAY, %.0s" $(seq 1 $max_length))
SFC_PHY1=$(printf "$SFC_PHY, %.0s" $(seq 1 $max_length))
CU_PHY1=$(printf "$CU_PHY, %.0s" $(seq 1 $max_length))
URBAN_PHY1=$(printf "$URBAN_PHY, %.0s" $(seq 1 $max_length))
NUM_SOIL_LAY1=$(printf "$NUM_SOIL_LAY, %.0s" $(seq 1 $max_length))
DUMMY1=$(printf "$DUMMY, %.0s" $(seq 1 $max_length))
################################################################################
#----------------------- Varibales preparation done --------------------------------------------------#
################################################################################

######################################################
#-----------------WPS--------------------------------#
######################################################
# Keep namelist.wps_master in your $WPS_DIR
#--------------------------------------------
if $RUN_WPS; then

mkdir -p $WORK_DIR/$INITIAL_DATE
cd $WORK_DIR/$INITIAL_DATE

cat >namelist.wps <<EOF
&share
 wrf_core = 'NMM',
 start_date= ${srt_date%,},
 end_date   = ${ed_date%,},
 max_dom = $max_length
 interval_seconds = $INTERVAL_SECONDS
 io_form_geogrid = 2,
  nocolons = T, 
/

&geogrid
 parent_id         =   1, 1, 2, 1, 4, 1, 6, 1, 8, 1, 10,
 parent_grid_ratio =   1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
 i_parent_start    =   1, $(IFS=,; echo "${namelist_isrt[*]}" | sed 's/,/, /g'),
 j_parent_start    =   1, $(IFS=,; echo "${namelist_jsrt[*]}" | sed 's/,/, /g'),
 e_we              =   $we1_points, $(IFS=,; echo "${namelist_we[*]}" | sed 's/,/, /g'),
 e_sn              =   $sn1_points, $(IFS=,; echo "${namelist_sn[*]}" | sed 's/,/, /g'),
 geog_data_res     = "2m", "2m", "2m", "2m", "2m", "2m", "2m", "2m", "2m",
  dx = $res_d1,
 dy = $res_d1,
 map_proj = "rotated_ll",
 ref_lat   =  $REF_LAT,
 ref_lon   =  $REF_LON,
 geog_data_path = '$WPS_GEOG_DIR'
 opt_geogrid_tbl_path='./'
 ref_x = 105.0,
 ref_y = 159.0,
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/

&metgrid
 fg_name = 'FILE'
 io_form_metgrid = 2, 
 opt_metgrid_tbl_path='./'
/

&mod_levs
  press_pa = 201300, 200100, 100000, 95000, 90000, 85000, 80000, 75000, 70000, 65000, 60000, 55000, 50000, 45000, 40000, 35000, 30000, 25000, 20000, 15000, 10000, 5000, 1000, 500, 200,
/
EOF
#----------------Geogrid------------------------------
ln -fs $WPS_DIR/geogrid.exe .
ln -sf $PARM_DIR/hwrf_GEOGRID.TBL ./GEOGRID.TBL
ln -sf $PARM_DIR/hwrf_METGRID.TBL ./METGRID.TBL
ln -sf $PARM_DIR/hwrf_Vtable_gfs2017 ./Vtable
ulimit -s unlimited
#-----------------Ungrib-------------------------------
./geogrid.exe

export LD_LIBRARY_PATH=/lib64:/usr/lib64:$LD_LIBRARY_PATH
$WPS_DIR/link_grib.csh $GFS_INPUT_DIR/gfs.0p25*

ln -fs $WPS_DIR/ungrib.exe .
#--------------------------------------------------------
ln -fs $WPS_DIR/metgrid.exe .

export LD_LIBRARY_PATH=/apps/iola_libs/lib:$LD_LIBRARY_PATH
##ln -sf /work2/09917/shyamamohanty06/stampede3/monsoon_geog_nc/geo_nmm* .
./ungrib.exe
./metgrid.exe

#rm -f GRIBFILE* FILE:*
echo "Creation of metgrid file is over"

fi
metlevel=`ncdump -h met_nmm.d01.${START_DATE}_00_00.nc | grep 'num_metgrid_levels = ' | cut -c23-24`
####landcat=`ncdump -h met_nmm.d01.$START_DATE:00:00.nc |grep 'NUM_LAND_CAT = ' | cut -c19-21`
######################################################
#-----------------REAL-------------------------------#
######################################################

if $RUN_REAL; then

cat >namelist.input <<EOF
&time_control
  start_year = ${srt_year%,} 
  start_month = ${srt_mon%,}
  start_day = ${srt_day%,} 
  start_hour = ${srt_hh%,}
  start_minute = 00, 00, 00, 00, 00, 00, 00, 00, 00, 00,
  start_second = 00, 00, 00, 00, 00, 00, 00, 00, 00, 00,
  end_year = ${fnl_year%,}
  end_month = ${fnl_mon%,}
  end_day = ${fnl_day%,} 
  end_hour = ${fnl_hh%,} 
  end_minute = 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00,
  end_second = 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00,
  interval_seconds = $INTERVAL_SECONDS,
  history_interval = $OUTPUT_FREQ_MOAD, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER,
  auxhist1_interval = $OUTPUT_FREQ_MOAD, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER,
  auxhist2_interval = $OUTPUT_FREQ_MOAD, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER,
  auxhist3_interval = $OUTPUT_FREQ_MOAD, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER, $OUTPUT_FREQ_INTER, $OUTPUT_FREQ_FINER,
  history_end = 0, 0, 0, 0, 0, 0, 0, 0, 0,
  auxhist2_end = 0, 0, 0, 0, 0, 0, 0, 0, 0,
  auxhist1_outname = "wrfdiag_d<domain>",
  auxhist2_outname = "wrfout_d<domain>_<date>",
  auxhist3_outname = "wrfout_d<domain>_<date>",
  frames_per_outfile = 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
  frames_per_auxhist1 = 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
  frames_per_auxhist2 = 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
  frames_per_auxhist3 = 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
  analysis = F, F, F, F, F, F, F, F, F, F, F,
  restart  = F,
  restart_interval = 36000,
  reset_simulation_start = F,
  io_form_input = 11,
  io_form_history = 11,
  io_form_restart = 11,
  io_form_boundary = 11,
  io_form_auxinput1 = 2,
  io_form_auxhist1 = 202,
  io_form_auxhist2 = 11,
  io_form_auxhist3 = 11,
  auxinput1_inname = "met_nmm.d<domain>.<date>",
  debug_level = 1,
  tg_reset_stream = 1,
  override_restart_timers = T,
  io_form_auxhist4 = 11,
  io_form_auxhist5 = 11,
  io_form_auxhist6 = 11,
  io_form_auxinput2 = 2,
  nocolons = T,
 /

&fdda

/

&domains
  time_step = $TIME_STEP,
  time_step_fract_num = 0,
  time_step_fract_den = 1,
  max_dom = $max_length,
  s_we = ${DUMMY1%,}
  e_we = $we1_points, $(IFS=,; echo "${namelist_we[*]}" | sed 's/,/, /g'),
  s_sn = ${DUMMY1%,}
  e_sn = $sn1_points, $(IFS=,; echo "${namelist_sn[*]}" | sed 's/,/, /g'),
  s_vert = ${DUMMY1%,}
  e_vert = ${E_VERT1%,}
  dx = $res_d1, $(IFS=,; echo "${namelist_resd[*]}" | sed 's/,/, /g'),
  dy = $res_d1, $(IFS=,; echo "${namelist_resd[*]}" | sed 's/,/, /g'),
  grid_id = 1, 2, 3, 4, 5, 6, 7, 8, 9,
  tile_sz_x = 0,
  tile_sz_y = 0,
  numtiles = 1,
  nproc_x = -1,
  nproc_y = -1,
  parent_id = 0, 1, 2, 1, 4, 1, 6, 1, 8, 1, 10,
  parent_grid_ratio = 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  parent_time_step_ratio = 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  i_parent_start = 1, $(IFS=,; echo "${namelist_isrt[*]}" | sed 's/,/, /g'),
  j_parent_start = 1, $(IFS=,; echo "${namelist_jsrt[*]}" | sed 's/,/, /g'),
  feedback = 1,
  num_moves = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  num_metgrid_levels = 34,
  p_top_requested = 1000.0,
  ptsgm = 15000.0,
  eta_levels = 1.0, 0.997622, 0.995078, 0.99224, 0.989036, 0.98544, 0.981451, 0.977061, 0.972249, 0.966994, 0.96128, 0.955106, 0.948462, 0.941306, 0.933562, 0.925134, 0.915937, 0.90589, 0.894913, 0.882926, 0.869842, 0.855646, 0.840183, 0.823383, 0.805217, 0.785767, 0.7651, 0.7432, 0.720133, 0.695967, 0.670867, 0.645033, 0.6187, 0.592067, 0.565333, 0.538733, 0.5125, 0.4868, 0.461767, 0.437533, 0.4142, 0.391767, 0.370233, 0.3496, 0.329867, 0.310967, 0.292867, 0.275533, 0.258933, 0.243, 0.2277, 0.213, 0.198867, 0.1853, 0.172267, 0.159733, 0.147633, 0.135967, 0.124767, 0.114033, 0.103733, 0.093867, 0.0844, 0.075333, 0.0666, 0.058267, 0.050333, 0.042833, 0.035733, 0.029, 0.0226, 0.0165, 0.010733, 0.005267, 0.0,
  use_prep_hybrid = F,
  num_metgrid_soil_levels = 4,
  corral_x = 9, 9, 9, 9, 9, 9, 9, 9, 9,
  corral_y = 18, 18, 18, 18, 18, 18, 18, 18, 18,
  smooth_option = 0,
/
  num_metgrid_levels = ${metlevel},

 &physics
  num_soil_layers = 4,
  mp_physics =${MP_PHYSICS1%,}
  ra_lw_physics = 4, 4, 4, 4, 4, 4, 4, 4, 4,
  ra_sw_physics = 4, 4, 4, 4, 4, 4, 4, 4, 4,
  sf_sfclay_physics  = ${SFC_LAY1%,}
  sf_surface_physics = ${SFC_PHY1%,}
  bl_pbl_physics = ${PBL_PHY1%,}
  cu_physics = ${CU_PHY1%}, 
  mommix = 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
  var_ric = 1.0,
  coef_ric_l = 0.16,
  coef_ric_s = 0.25,
  h_diff = 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
  gwd_opt = 2, 0, 0, 0, 0, 0, 0, 0, 0
  sfenth = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  nrads = 30, 90, 270, 270, 270, 270, 270, 270, 270,
  nradl = 30, 90, 270, 270, 270, 270, 270, 270, 270,
  nphs = 2, 6, 6, 6, 6, 6, 6, 6, 6,
  ncnvc = 2, 6, 6, 6, 6, 6, 6, 6, 6,
  ntrack = 6, 6, 18, 6, 18, 6, 18, 6, 18,
  gfs_alpha = -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0,
  sas_pgcon = 0.55, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2,
  sas_mass_flux = 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
  co2tf = 1,
  vortex_tracker = 2, 2, 2, 2, 2, 2, 2, 2, 2
  nomove_freq = 0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0,
  tg_option = 1,
  ntornado = 2, 6, 18, 6, 18, 6, 18, 6, 18, 6, 18,
  cldovrlp = 4,
  ens_cdamp = 0.2,
  ens_pblamp = 0.2,
  ens_random_seed = 99,
  ens_sasamp = 50.0,
  ensda_physics_pert = 1,
  icloud = 3,
  icoef_sf = 6, 6, 6, 6, 6, 6, 6, 6, 6,
  iwavecpl = 0, 0, 0, 0, 0, 0, 0, 0, 0,
  lcurr_sf = F, F, F, F, F, F, F, F, F,
  pert_cd = F,
  pert_pbl = F,
  pert_sas = F,
/

&dynamics
  non_hydrostatic = T, T, T, T, T, T, T, T, T,
  euler_adv = F,
  wp = 0, 0, 0, 0, 0, 0, 0, 0, 0,
  coac = 1.5, 2.0, 2.6, 2.6, 2.6, 2.6, 2.6, 2.6, 2.6,
  codamp = 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0,
  terrain_smoothing = 2,
  dwdt_damping_lev = 2000.0, 2000.0, 2000.0, 2000.0, 2000.0, 2000.0, 2000.0, 2000.0, 2000.0,
/

&bdy_control
  spec_bdy_width = 1,
  specified = T,
/

&namelist_quilt
  poll_servers = F,
  nio_tasks_per_group = 0,
  nio_groups = 1,
/

&logging
  compute_tasks_silent = T,
  io_servers_silent = T,
  stderr_logging = 0,
/
EOF


ln -fs $WRF_DIR/main/real_nmm.exe .
ln -fs $WRF_DIR/main/wrf.exe .

ln -fs $FIX/hwrf_eta_micro_lookup.dat ./eta_micro_lookup.dat
ln -fs $FIX/hwrf-wrf/aerosol* .
ln -fs $FIX/hwrf-wrf/bulk* .
ln -fs $FIX/hwrf-wrf/CAM* .
ln -fs $FIX/hwrf-wrf/capacity* .
ln -fs $FIX/hwrf-wrf/CCN* .
ln -fs $FIX/hwrf-wrf/CLM* .
ln -fs $FIX/hwrf-wrf/co2* .
ln -fs $FIX/hwrf-wrf/coeff* .
ln -fs $FIX/hwrf-wrf/constants* .
ln -fs $FIX/hwrf-wrf/ETA* .
ln -fs $FIX/hwrf-wrf/grib* .
ln -fs $FIX/hwrf-wrf/kernels* .
ln -fs $FIX/hwrf-wrf/*.TBL .
ln -fs $FIX/hwrf-wrf/masses* .
ln -fs $FIX/hwrf-wrf/ozone* .
ln -fs $FIX/hwrf-wrf/README* .
ln -fs $FIX/hwrf-wrf/RRTM* .
ln -fs $FIX/hwrf-wrf/tr67* .
ln -fs $FIX/hwrf-wrf/term* .
ln -fs $FIX/hwrf-wrf/wind-turbine-1.tbl .
####./real.exe

cat >running_job.sh <<EOF
#!/bin/bash

#SBATCH -J hwrf           # Job name
#SBATCH -o hwrf.o%j       # Name of stdout output file
#SBATCH -e hwrf.e%j       # Name of stderr error file
#SBATCH -p skx          # Queue (partition) name
#SBATCH -N 5               # Total # of nodes
#SBATCH -t 24:00:00        # Run time (hh:mm:ss)
#SBATCH --mail-type=all    # Send email at begin and end of job
#SBATCH -A ATM24007       # Project/Allocation name (req'd if you have more than 1)
#SBATCH --mail-user=krishna.osuri@utexas.edu

# Any other commands must follow all #SBATCH directives...
. /work/09534/st37357/ls6/intel/oneapi/setvars.sh


# Launch MPI code...
ibrun ./real_nmm.exe > real.log     
ibrun ./wrf.exe > wrf.log
EOF

####chmod 755 running_job.sh

#mpirun -np 64 ./real_nmm.exe
#mpirun -np 96 ./wrf.exe

fi
#------------------------------------------------------------------------------------


export INITIAL_DATE=`$ndateExe $CYCLE_PERIOD $INITIAL_DATE`
###export FINAL_DATE=`$ndateExe ${FCST_RANGE} $INITIAL_DATE`
###let FCST_TIME=$FCST_RANGE-$CYCLE_PERIOD
###export FCST_RANGE=$FCST_TIME
###echo $FCST_RANGE

done

echo  '"Hey Job Completed Successfuly"'
exit

