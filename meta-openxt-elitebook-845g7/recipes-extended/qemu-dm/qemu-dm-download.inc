# wiki.qemu-project.org/download is gone (404). Fetch the same tarball
# (checksums unchanged) from download.qemu.org, as done in
# apertussolutions/xenclient-oe 0aea4c87.
PREMIRRORS_prepend = "http://wiki.qemu-project.org/download/.* https://download.qemu.org/ \n"
