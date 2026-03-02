#!/bin/sh

container_name=ubuntu20_android
workspace_dir=/home/karlt/Workspace/mnt_2t/mediatek
uid=1000

# Check container state and act accordingly
container_state=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null)

if [ "$container_state" = "running" ]; then
    echo "Container '$container_name' is already running. Re-entering..."
    docker exec -e UID=$uid -ti -u $uid -w /home/ubq/workspace ${container_name} /bin/bash

elif [ "$container_state" = "exited" ]; then
    echo "Container '$container_name' exists but stopped. Starting..."
    docker start ${container_name}
    docker exec -e UID=$uid -ti -u $uid -w /home/ubq/workspace ${container_name} /bin/bash

else
    echo "Creating new container '$container_name'..."
    docker run --name ${container_name} -e workspace_dir -it -d \
        -v $workspace_dir:/home/ubq/workspace -v /lib/modules:/lib/modules \
        -v $workspace_dir/docker_ubuntu20/create-user.sh:/bin/create-user.sh \
        --privileged -v /dev/:/dev -v /run/udev:/run/udev public.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-20.04:latest /bin/bash
    docker exec -e UID=$uid -it ${container_name} /bin/create-user.sh $uid
    docker exec -e UID=$uid -it -u $uid -w /home/ubq/workspace ${container_name} /bin/bash
fi
