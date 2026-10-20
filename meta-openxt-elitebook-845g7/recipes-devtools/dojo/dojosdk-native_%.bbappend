# The Dojo build tool only needs a Java runtime to run its bundled Rhino.
# xenclient-oe builds one from source (icedtea7-native), which pulls in the
# whole meta-java bootstrap chain; many of its sources are no longer
# downloadable (archive.apache.org returns 403, several upstream sites are
# gone) and it costs hours of build time. Use the host Java instead (added to
# HOSTTOOLS in conf/layer.conf, provided by elitebook-845g7/docker).
DEPENDS_remove = "icedtea7-native"
