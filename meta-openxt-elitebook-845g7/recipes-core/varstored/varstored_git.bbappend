# uefi.org no longer serves dbxupdate_x64.bin at the URL xenclient-oe uses.
# Microsoft publishes the same signed DBX update in its secureboot_objects
# repository; this commit holds a byte-identical copy of the file the recipe
# pins (same sha256), so the checksum in varstored_git.bb stays valid.
SRC_URI_remove = "https://uefi.org/sites/default/files/resources/dbxupdate_x64.bin;downloadfilename=dbx.auth"
SRC_URI_append = " https://raw.githubusercontent.com/microsoft/secureboot_objects/6740d7339f181bd2b295bfd605a1fbceb6be4684/PostSignedObjects/DBX/amd64/DBXUpdate.bin;downloadfilename=dbx.auth"
