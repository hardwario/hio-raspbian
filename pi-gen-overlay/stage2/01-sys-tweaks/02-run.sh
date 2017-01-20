#!/bin/bash -e

# Apply timezone changes.
# Note: Change via debconf doesn't work, so we do it directly and use
# dpkg-reconfigure just to update /etc/localtime.
on_chroot <<-EOF
	echo 'Europe/Prague' > /etc/timezone
	dpkg-reconfigure -f noninteractive tzdata
EOF
