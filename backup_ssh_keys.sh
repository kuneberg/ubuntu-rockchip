#!/bin/bash

# --- Configuration Variables ---
REMOTE_USER="ubuntu"
REMOTE_HOST="192.168.68.65"
REMOTE_SSH_DIR="/home/${REMOTE_USER}/.ssh"
ARCHIVE_NAME="lockbox.ssh.tar.gz" # Fixed archive name as requested
REMOTE_TEMP_PATH="/tmp/${ARCHIVE_NAME}"
LOCAL_DEST_DIR="." # Current directory

echo "--- Starting SSH Key Backup Process ---"
echo "Remote Host: ${REMOTE_USER}@${REMOTE_HOST}"

# 1. Compress the .ssh directory on the remote host
echo "1. Compressing ${REMOTE_SSH_DIR} on the remote host..."
# We use 'tar' to compress the directory.
# -c: Create archive
# -z: Compress with gzip
# -f: Specify filename
# -C /home/ubuntu: Change directory before processing (.ssh is relative to this parent)
# .ssh: The directory to archive
ssh ${REMOTE_USER}@${REMOTE_HOST} "tar -czf ${REMOTE_TEMP_PATH} -C /home/${REMOTE_USER} .ssh"

# Check if the remote tar command was successful
if [ $? -eq 0 ]; then
    echo "Compression successful. Archive created at ${REMOTE_TEMP_PATH}."

    # 2. Copy the archive from the remote host to the local directory
    echo "2. Copying archive from remote host to ${LOCAL_DEST_DIR}..."
    # 'scp' is used for secure file transfer
    scp ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TEMP_PATH} ${LOCAL_DEST_DIR}

    # Check if the scp command was successful
    if [ $? -eq 0 ]; then
        echo "Transfer complete. File saved locally as ${ARCHIVE_NAME}"

        # 3. Clean up the temporary file on the remote host
        echo "3. Cleaning up temporary archive on remote host..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "rm ${REMOTE_TEMP_PATH}"
        echo "Cleanup complete."
    else
        echo "ERROR: SCP transfer failed."
    fi
else
    echo "ERROR: Remote compression failed."
fi

echo "--- Script Finished ---"