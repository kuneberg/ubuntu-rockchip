#!/bin/bash

# --- Configuration Variables ---
REMOTE_USER="ubuntu"
REMOTE_HOST="192.168.68.65"
ARCHIVE_NAME="ubuntu-rockchip.tar.gz"
LOCAL_ARCHIVE_PATH="./${ARCHIVE_NAME}"
# This is the directory where the archive is initially placed on the remote host (e.g., /home/ubuntu/)
REMOTE_ARCHIVE_DIR="/home/${REMOTE_USER}"
# This is the full path to the archive file on the remote host
REMOTE_ARCHIVE_PATH="${REMOTE_ARCHIVE_DIR}/${ARCHIVE_NAME}"
# This is the directory where the archive contents will be UNPACKED (e.g., /home/ubuntu/ubuntu-rockchip/)
REMOTE_TARGET_DIR="${REMOTE_ARCHIVE_DIR}/ubuntu-rockchip"


echo "--- Starting Directory Deployment Process ---"
echo "Remote Host: ${REMOTE_USER}@${REMOTE_HOST}"
echo "Archive Name: ${ARCHIVE_NAME}"

# 1. Compress the current local directory
echo "1. Compressing current directory into ${ARCHIVE_NAME}..."
# FIX: Using COPYFILE_DISABLE=1 is the definitive method on macOS to prevent
# extended attributes (xattrs) from being included, which eliminates LIBARCHIVE warnings.
COPYFILE_DISABLE=1 tar -czf "${LOCAL_ARCHIVE_PATH}" \
    --exclude="./${ARCHIVE_NAME}" \
    .

# Check if the compression was successful
if [ $? -ne 0 ]; then
    echo "ERROR: Local compression failed."
    exit 1
fi
echo "Compression successful."

# 2. Copy the archive from the local machine to the remote host's home directory
echo "2. Copying archive to remote host at ${REMOTE_ARCHIVE_DIR}..."
# 'scp' is used for secure file transfer
scp "${LOCAL_ARCHIVE_PATH}" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_ARCHIVE_DIR}

# Check if the scp command was successful
if [ $? -ne 0 ]; then
    echo "ERROR: SCP transfer failed."
    # Clean up local archive on transfer failure
    rm "${LOCAL_ARCHIVE_PATH}"
    exit 1
fi
echo "Transfer successful."

# 3. Execute commands on the remote host (Unpack and Clean up)
echo "3. Unpacking archive on remote host into ${REMOTE_TARGET_DIR} and cleaning up..."
# Using a single ssh call to execute multiple commands sequentially
ssh ${REMOTE_USER}@${REMOTE_HOST} "
    # 1. Create the target directory if it doesn't exist (e.g., /home/ubuntu/ubuntu-rockchip)
    echo \"[REMOTE INFO] Creating target directory: ${REMOTE_TARGET_DIR}...\"
    mkdir -p ${REMOTE_TARGET_DIR} || exit 1

    # 2. Change directory to the target location for unpacking
    cd ${REMOTE_TARGET_DIR} || exit 1

    # 3. Unpack the archive from the source directory (-x: extract, -z: gzip, -f: file)
    echo \"[REMOTE INFO] Unpacking ${ARCHIVE_NAME} into current directory...\"
    # CORRECTED: Changed REMETE_ARCHIVE_PATH to REMOTE_ARCHIVE_PATH
    tar -xzf ${REMOTE_ARCHIVE_PATH}
    if [ \$? -ne 0 ]; then
        echo \"[REMOTE ERROR] Failed to unpack archive.\"
        exit 1
    fi

    # 4. Clean up the temporary file (the archive) from its original location
    echo \"[REMOTE INFO] Cleaning up remote archive: ${REMOTE_ARCHIVE_PATH}...\"
    rm ${REMOTE_ARCHIVE_PATH}
    echo \"[REMOTE INFO] Deployment complete.\"
"

# 4. Clean up local archive
echo "4. Cleaning up local archive..."
rm "${LOCAL_ARCHIVE_PATH}"
echo "Local cleanup complete."

echo "--- Script Finished Successfully ---"
