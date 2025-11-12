#!/bin/bash

# --- Configuration Variables ---
REMOTE_USER="ubuntu"
REMOTE_HOST="192.168.68.65"
ARCHIVE_NAME="lockbox.ssh.tar.gz" # Archive name must match the backup script
REMOTE_TEMP_PATH="/tmp/${ARCHIVE_NAME}"
LOCAL_ARCHIVE_PATH="./${ARCHIVE_NAME}"
REMOTE_SSH_DIR="/home/${REMOTE_USER}/.ssh"
PRIVATE_KEY_PATH="${REMOTE_SSH_DIR}/id_ed25519"

echo "--- Starting SSH Key Deployment Process ---"
echo "Remote Host: ${REMOTE_USER}@${REMOTE_HOST}"
echo "Archive to Deploy: ${LOCAL_ARCHIVE_PATH}"

# Check if the local archive file exists
if [ ! -f "${LOCAL_ARCHIVE_PATH}" ]; then
    echo "ERROR: Local archive file not found at ${LOCAL_ARCHIVE_PATH}"
    echo "Please ensure 'lockbox.ssh.tar.gz' is in the current directory."
    exit 1
fi

# 1. Copy the archive from the local machine to the remote host's /tmp directory
echo "1. Copying local archive to remote host..."
# 'scp' is used for secure file transfer
scp "${LOCAL_ARCHIVE_PATH}" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TEMP_PATH}

# Check if the scp command was successful
if [ $? -ne 0 ]; then
    echo "ERROR: SCP transfer failed."
    exit 1
fi
echo "Transfer successful."

# 2. Execute commands on the remote host (Unpack, set permissions, setup agent)
echo "2. Unpacking archive and setting up SSH agent on remote host..."
# Using a single ssh call to execute multiple commands sequentially
ssh ${REMOTE_USER}@${REMOTE_HOST} "
    # Navigate to the user's home directory
    cd /home/${REMOTE_USER} || exit 1

    # Unpack the archive, overwriting/creating the .ssh directory
    # -x: extract, -z: gzip, -f: file. Tar will overwrite the .ssh directory inside the home folder.
    tar -xzf ${REMOTE_TEMP_PATH}
    if [ \$? -ne 0 ]; then
        echo \"[REMOTE ERROR] Failed to unpack archive.\"
        exit 1
    fi

    # Set appropriate permissions for the .ssh directory (Crucial for security)
    chmod 700 ${REMOTE_SSH_DIR}
    # Set permissions for private keys
    chmod 600 ${PRIVATE_KEY_PATH}

    # Start SSH Agent and add key (Agent will terminate when this SSH command finishes)
    echo \"[REMOTE INFO] Starting SSH Agent and adding key (Agent will terminate after this script ends).\"
    eval \"\$(ssh-agent -s)\"
    ssh-add ${PRIVATE_KEY_PATH}

    # Clean up the temporary file
    rm ${REMOTE_TEMP_PATH}
    echo \"[REMOTE INFO] Cleanup complete. Keys deployed.\"
"

# Check if the remote command execution was successful
if [ $? -eq 0 ]; then
    echo "--- Deployment Finished Successfully ---"
else
    echo "--- Deployment Failed During Remote Execution ---"
fi