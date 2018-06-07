#!/bin/bash

# An Arduino's serial port is registered to /dev/ttyACM0 on Ubuntu 14.04.
# However matlab REQUIRES the serial port to be available at /dev/ttyS[0-255].
# This is a known issue:
# http://nl.mathworks.com/matlabcentral/answers/95024-why-is-my-serial-port-not-recognized-with-matlab-on-linux-or-solaris

# The proposed solution is to make a symlink from the Arduino to a name Matlab
# will accept.
sudo ln -s /dev/ttyACM0 /dev/ttyS200

# Additionally, matlab creates a lock file in
#  /var/lock/LCK..ttyS200
# which it does not clean up if it ungracefully quits. If this file is present
# you cannot connect to the serial port with matlab.
# You can remove it by hand to allow you to connect again.