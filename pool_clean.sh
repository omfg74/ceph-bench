#!/bin/bash

set -e -u

pool=prod

images=$( rbd -p "$pool" ls )

regexp='rbd_directory|rbd_children|rbd_info'
for image in $images; do
    prefix=$( rbd --format=json info "$pool/$image" | jq -r .block_name_prefix )
    [[ "$prefix" =~ ^rbd_data\.([a-f0-9]+)$ ]] || exit 1
    #echo "$image - $prefix"
    image_id=${BASH_REMATCH[1]}
    regexp="$regexp|rbd_header[.]$image_id|rbd_id[.]$image|rbd_object_map[.]$image_id|rbd_data[.]$image_id[.][a-f0-9]+"
done
regexp="^($regexp)\$"

rados -p "$pool" ls | egrep -v "$regexp" > extra.txt

while read line; do
    rados -p "$pool" stat "$line"
done < extra.txt > sizes.txt
