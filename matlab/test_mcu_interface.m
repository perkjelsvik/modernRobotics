% Example script on how to use the raw MCUInterface class 

PACKET_SIZE = 16;  % packet length
MSG_TYPE_FORMAT = 'H'; % uint16_t as message type
% Mesage format specification, entries of {message_type, message_name, message_value_fmt}
messages = {...
    {1, 'set_joints_position_speed', 'hhhhhhh'}, ...
    {2, 'get_joints_position_speed', 'hhhhhhh'}, ...
    {3, 'get_status', 'IH'}, ...
    {4, 'get_version', 'IBB'}, ...
};

% create the interface
interface = MCUInterface(PACKET_SIZE, MSG_TYPE_FORMAT, messages);
interface.open('/dev/tty.usbmodem1421', 115200) % open the serial port /dev/ttyS200 at 115200 baudrate.
% or specify the timeout:
%int.open('/dev/ttyS200', 115200, 0.0001)
pause(1.5); % idle for a bit to let Matlab open the serial port.

% Write the get_version message
interface.write_message(interface.Type.get_version);

% Read the response
[type, response] = interface.read_message();
if (type == interface.Type.get_version)
    disp('Successfully retrieved version.');
    magic_identifier = response(1)
    firmare_version = response(2:end)
else
    disp('Failed to retrieve the version');
end