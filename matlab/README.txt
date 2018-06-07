The scripts in this folder are used to communicate with and control the robot arm.
The most important script is robot_control_skeleton, which contains all the “scaffolding” to execute a control loop.

Linux users: you might need to do some trickery with your serial port mapping; see readme_linux_users.sh.


INTERFACE CLASSES (don't use directly)
ArmInterface.m
    Interface to the robot arm, containing functions to set the joint positions, read the speed, et cetera.
MCUInterface.m
    Serial interface to a microcontroller connected to Matlab.
cStruct.m
    Helper script that allows communication using structs

TEST SCRIPTS (probably don't need these)
test_arm_q.m
    Test sending joint angles (in radians) to the robot arm, and reading back the joint angles (in radians)
test_arm_read_fail.m
    Test reliability of communication.
test_mcu_interface.m
    Low-level test for the serial interface to the microcontroller in the robot arm.
test_mcu_interface_async.m
    Low-level test for asynchronous communication with the microcontroller.

PRACTICAL SCRIPTS
arm_example.m
    Script that moves the arm about a bit to show how the interface works.
robot_control_skeleton.m
    Script containing all “scaffolding” to execute a control loop. This is the script you fill in and/or adapt during the actual practical.
plot_robot3.m
    Visualises the robot in a 3D-plot; used in robot_control_skeleton.