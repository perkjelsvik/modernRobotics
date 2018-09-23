clear all % Clear all stuff, closing serial ports already open.

% Create the arm and connect to it
arm = ArmInterface();
res = arm.open('/dev/tty.usbmodem1421');
pause(1.5) % Give matlab the time to open the serial port.

% Retrieve the arm firmware version and print it.
v = arm.get_version();
disp(['Arm firmware version: ' num2str(v(1)) '.' num2str(v(2))])
pause(2)

endpos = 600;
servo_speed = 100;
startpos = 400;

disp(['Moving to ' num2str(startpos) ', ' num2str(startpos) ', ' num2str(startpos) ])
% Move the arm with default speed to the start positions.
arm.set_position([startpos, startpos, startpos]);
pause(1)


disp(['Sweeping to ' num2str(endpos) ', ' num2str(endpos) ', ' num2str(endpos) ])

for setpoint=startpos:endpos
    % Move the joints to the setpoints with the provided speeds
    arm.set_position_speed([setpoint, setpoint, setpoint], [servo_speed, servo_speed, servo_speed]);

    [actual_pos speed] = arm.get_position_speed();
    disp(['Requested positions: ' num2str(setpoint) ' read: ' num2str(actual_pos(1)) ', ' num2str(actual_pos(2)) ', ' num2str(actual_pos(3))])

    % Sleep for a bit to give the servos time to get to that position.
    pause(0.001)
    
end
% Retrieve the status and number of transmission errors the MCU recorded.
[uptime transmission_errors] = arm.get_status();
disp(['MCU uptime: ' num2str(uptime) ' transmission errors: ' num2str(transmission_errors)]);

% Close the serial port, 'clear a' also works to close it.
arm.close()