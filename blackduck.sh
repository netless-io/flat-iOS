export BD_HUB_TOKEN=$1
DATE=$(date +"%Y-%m-%d-%H-%m-%S-%s")

echo $2 |awk '{run=$0;system(run)}'
