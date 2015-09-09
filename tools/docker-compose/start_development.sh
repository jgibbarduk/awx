#!/bin/bash

# We need to give the databases enough time to start up (switch to using ansible's wait_for here)
sleep 20

# In case Tower in the container wants to connect to itself, use "docker exec" to attach to the container otherwise
/etc/init.d/ssh start
ansible -i "127.0.0.1," -c local -v -m postgresql_user -U postgres -a "name=awx-dev password=AWXsome1 login_user=postgres login_host=postgres" all
ansible -i "127.0.0.1," -c local -v -m postgresql_db -U postgres -a "name=awx-dev owner=awx-dev login_user=postgres login_host=postgres" all

# Move to the source directory so we can bootstrap
if [ -f "/tower_devel/manage.py" ]; then
    cd /tower_devel
elif [ -f "/tower_devel/ansible-tower/manage.py" ]; then
    cd /tower_devel/ansible-tower
else
    echo "Failed to find tower source tree, map your development tree volume"
fi
make develop

# Check if we need to build dependencies
if [ -f "awx/lib/.deps_built" ]; then
    echo "Skipping dependency build - remove awx/lib/.deps_built to force a rebuild"
else
    make requirements_dev
    touch awx/lib/.deps_built
fi

# Tower bootstrapping
make version_file
make migrate
make init

# Start the service
make honcho