clear all % Clear all stuff, closing serial ports already open.

% Create the arm and connect to it
arm = ArmInterface();
res = arm.open('/dev/ttyS200');
pause(1.5) % Give matlab the time to open the serial port.

% Retrieve the arm firmware version and print it.
v = arm.get_version();
disp(['Arm firmware version: ' num2str(v(1)) '.' num2str(v(2))])
pause(2)

endpos = pi/4;
servo_speed = 50;
startpos = -pi/4;

disp(['Moving to ' num2str(startpos) ', ' num2str(startpos) ', ' num2str(startpos) ])
% Move the arm with default speed to the start positions.
arm.set_position([startpos, startpos, startpos]);
pause(1)

arm.set_default_speed(servo_speed);


disp(['Sweeping to ' num2str(endpos) ', ' num2str(endpos) ', ' num2str(endpos) ])

for setpoint=startpos:pi/1000:endpos
    % Move the joints to the setpoints with the provided speeds
    arm.set_q([setpoint, setpoint, setpoint]);

    [actual_pos, res] = arm.get_q();
    if (~res)
        warning('Retrieving position failed.')
    end
    disp(['Requested q: ' num2str(setpoint) ' read: ' num2str(actual_pos(1)) ', ' num2str(actual_pos(2)) ', ' num2str(actual_pos(3))])

    % Sleep for a bit to give the servos time to get to that position.
    pause(0.1)
    
end
% Retrieve the status and number of transmission errors the MCU recorded.
[uptime transmission_errors] = arm.get_status();
disp(['MCU uptime: ' num2str(uptime) ' transmission errors: ' num2str(transmission_errors)]);

% Close the serial port, 'clear a' also works to close it.
arm.close()