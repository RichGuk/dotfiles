#!/bin/bash

###############################################################################
# Simple backup script for macbook.
#
# This script simply rsync's my home dir to a sparse bundle (to maintain xattrs
# as much as possible). It keeps history for up to 30 days, should in theory
# run every hour. It's simple. :)
#
# Requires rsync 3.
# brew install https://raw.githubusercontent.com/Homebrew/homebrew-dupes/master/rsync.rb
#
# Bits borrowed from:
# - http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync/
###############################################################################

SRC="/Users/rich"
DST="/Volumes/Striker MBP backup"
EXCLUDE="/Users/rich/.dotfiles/.backupignore"
KEEP_DAYS=30
DATE=`date "+%Y-%m-%dT%H:%M:%S"`

# Get sudo access now.
sudo -v

##############################################################
PROG=$0

if [ ! -r "$SRC" ]; then
  logger -t $PROG "Source $SRC not readable - Cannot start the sync process"
  exit;
fi

if [ ! -w "$DST" ]; then
  logger -t $PROG "Destination $DST not writeable - Cannot start the sync process"
  exit;
fi

# --acls                   update the destination ACLs to be the same as the source ACLs
# --archive                turn on archive mode (recursive copy + retain attributes)
# --delete                 delete any files that have been deleted locally
# --delete-excluded        delete any files (on DST) that are part of the list of excluded files
# --exclude-from           reference a list of files to exclude
# --hard-links             preserve hard-links
# --one-file-system        don't cross device boundaries (ignore mounted volumes)
# --sparse                 handle sparse files efficiently
# --verbose                increase verbosity
# --xattrs                 update the remote extended attributes to be the same as the local ones
logger -t $PROG "Start rsync"
sudo rsync --acls \
           --archive \
           --delete \
           --delete-excluded \
           --exclude-from=$EXCLUDE \
           --hard-links \
           --one-file-system \
           --sparse \
           --verbose \
           --xattrs \
           --link-dest="$DST/current" \
           "$SRC" "$DST/backup-$DATE"

pushd "$DST" >>/dev/null
unlink current
ln -s "backup-$DATE" current
sudo find "$DST" -type d -depth 1 -mmin +5 -exec rm -rf {} \;
popd>>/dev/null

echo "Done."
exit 0
