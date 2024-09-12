#!/bin/bash

# Define paths and filenames
BIN_DIR="bin"
SPLIT_IMG_DIR="split_img"
IMAGE_FILE="Image.gz"
KERNEL_FILE="boot.img-kernel"
OUTPUT_DIR="output"
UNSIGNED_IMG="unsigned-new.img"
FINAL_IMG="boot.img"
LOG_FILE="script.log"
RAMDISK_DIR="ramdisk"

# Function to run a command with sudo and log output
run_with_sudo() {
  echo "Running: sudo $@" | tee -a "$LOG_FILE"
  sudo "$@" 2>&1 | tee -a "$LOG_FILE"
}

# Function to log and run a command
run_and_log() {
  local command="$@"
  echo "Running: $command" | tee -a "$LOG_FILE"
  eval "$command" 2>&1 | tee -a "$LOG_FILE"
}

# Function to ensure directory ownership and permissions
ensure_permissions() {
  echo "Ensuring permissions for directories..." | tee -a "$LOG_FILE"
  run_with_sudo chown -R itachi:itachi "$BIN_DIR" "$SPLIT_IMG_DIR" "$OUTPUT_DIR" "$RAMDISK_DIR"
  run_with_sudo chmod 755 "$BIN_DIR" "$SPLIT_IMG_DIR" "$OUTPUT_DIR" "$RAMDISK_DIR"
}

# Function to ensure file ownership and permissions
ensure_file_permissions() {
  echo "Ensuring permissions for files..." | tee -a "$LOG_FILE"
  if [ -f "$OUTPUT_DIR/$FINAL_IMG" ]; then
    run_with_sudo chown itachi:itachi "$OUTPUT_DIR/$FINAL_IMG"
    run_with_sudo chmod 644 "$OUTPUT_DIR/$FINAL_IMG"
  fi
}

# Function to pack the kernel
pack_kernel() {
  echo "Packing kernel..." | tee -a "$LOG_FILE"
  if [ ! -f "$BIN_DIR/$IMAGE_FILE" ]; then
    echo "Error: $BIN_DIR/$IMAGE_FILE does not exist." | tee -a "$LOG_FILE"
    exit 1
  fi

  ensure_permissions

  run_with_sudo bash cleanup.sh
  run_with_sudo bash unpackimg.sh

  echo "Moving $BIN_DIR/$IMAGE_FILE to $SPLIT_IMG_DIR and renaming it to $KERNEL_FILE..." | tee -a "$LOG_FILE"
  run_with_sudo mv "$BIN_DIR/$IMAGE_FILE" "$SPLIT_IMG_DIR/$KERNEL_FILE"

  run_with_sudo bash repackimg.sh

  if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating output directory..." | tee -a "$LOG_FILE"
    run_with_sudo mkdir -p "$OUTPUT_DIR"
  fi

  echo "Moving $UNSIGNED_IMG to $OUTPUT_DIR as $FINAL_IMG..." | tee -a "$LOG_FILE"
  run_with_sudo mv "$UNSIGNED_IMG" "$OUTPUT_DIR/$FINAL_IMG"

  ensure_file_permissions

  echo "Kernel packing completed." | tee -a "$LOG_FILE"
}

# Function to run cleanup
cleanup() {
  echo "Running cleanup.sh..." | tee -a "$LOG_FILE"
  run_with_sudo bash cleanup.sh
}

# Function to run unpackimg
unpackimg() {
  echo "Running unpackimg.sh..." | tee -a "$LOG_FILE"
  run_with_sudo bash unpackimg.sh
}

# Function to run repackimg
repackimg() {
  echo "Running repackimg.sh..." | tee -a "$LOG_FILE"
  run_with_sudo bash repackimg.sh
}

# Function to cleanup all buffers
cleanup_all() {
  echo "Cleaning up all buffers..." | tee -a "$LOG_FILE"
  if [ -f "$BIN_DIR/$IMAGE_FILE" ]; then
    echo "Removing $BIN_DIR/$IMAGE_FILE..." | tee -a "$LOG_FILE"
    run_with_sudo rm "$BIN_DIR/$IMAGE_FILE"
  fi
  if [ -f "$OUTPUT_DIR/$FINAL_IMG" ]; then
    echo "Removing $OUTPUT_DIR/$FINAL_IMG..." | tee -a "$LOG_FILE"
    run_with_sudo rm "$OUTPUT_DIR/$FINAL_IMG"
  fi
  if [ -f "$UNSIGNED_IMG" ]; then
    echo "Removing $UNSIGNED_IMG..." | tee -a "$LOG_FILE"
    run_with_sudo rm "$UNSIGNED_IMG"
  fi
  echo "All buffers cleared." | tee -a "$LOG_FILE"
}

# Initialize log file
echo "Script started at $(date)" > "$LOG_FILE"

# Show menu and handle user input
echo "Select an option:"
echo "1: Pack Kernel"
echo "2: Cleanup"
echo "3: Unpack Image"
echo "4: Repack Image"
echo "5: Cleanup All"
read -p "Enter your choice (1-5): " choice

case "$choice" in
  1) pack_kernel ;;
  2) cleanup ;;
  3) unpackimg ;;
  4) repackimg ;;
  5) cleanup_all ;;
  *) echo "Invalid option. Please select a number between 1 and 5." | tee -a "$LOG_FILE" ;;
esac

echo "Script ended at $(date)" | tee -a "$LOG_FILE"
