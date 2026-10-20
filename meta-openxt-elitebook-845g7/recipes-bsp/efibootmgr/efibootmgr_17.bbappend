# efibootmgr's "master" branch no longer exists (the default branch is now
# "main"); the pinned SRCREV is still on "rawhide". BitBake verifies that
# SRCREV is on the named branch, so the dunfell recipe fails to fetch.
SRC_URI_remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=master"
SRC_URI_prepend = "git://github.com/rhboot/efibootmgr.git;protocol=https;branch=rawhide "
