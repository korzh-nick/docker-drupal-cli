#!/bin/bash

# Default SSH key name
if [ -z $SSH_KEY_NAME ]; then $SSH_KEY_NAME='id_rsa'; fi
echo "Using SSH key name: $SSH_KEY_NAME"

# Copy SSH key pairs.
# @param $1 path to .ssh folder
copy_ssh_key ()
{
  local path="$1/$SSH_KEY_NAME"
  if [ -f $path ]; then
    echo "Copying SSH key $path from host..."
    cp $path* ~/.ssh/
    chmod 600 ~/.ssh/$SSH_KEY_NAME*
  fi
}

# Copy Acquia Cloud API credentials
# @param $1 path to the home directory (parent of the .acquia directory)
copy_dot_acquia ()
{
  local path="$1/.acquia/cloudapi.conf"
  if [ -f $path ]; then
    echo "Copying Acquia Cloud API settings in $path from host..."
    mkdir -p ~/.acquia
    cp $path ~/.acquia
  fi
}

# Copy SSH keys from host if available
copy_ssh_key '/.home-linux/.ssh' # Linux (current)
copy_ssh_key '/.home-b2d/.ssh' # boot2docker (current)
copy_ssh_key '/.ssh' # Linux (legacy)
copy_ssh_key '/.ssh-b2d' # boot2docker (current)

# Copy Acquia Cloud API credentials from host if available
copy_dot_acquia '/.home-linux' # Linux
copy_dot_acquia '/.home-b2d' # boot2docker

# Execute passed CMD arguments
exec "$@"
