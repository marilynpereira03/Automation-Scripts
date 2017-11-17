filename=credential.json
#parse region name
region=$(jq .region[] $filename)

set -f
  regionArray=(${region//,/ })
  for i in "${!regionArray[@]}"
  do
      regionArray[$i]=$(echo ${regionArray[i]} | sed 's/","/,/g; s/^"\|"$//g')
      echo ${regionArray[i]}
  done

  total_instance=0
  count=$(jq .count[] $filename)

  countArray=(${count//,/ })
  for i in "${!countArray[@]}"
  do
    echo ${countArray[$i]}
    total_instance=$(( $total_instance + ${countArray[$i]} ))

  done
  echo "total_instance $total_instance"
#Only for tsting purpose
#One more time
