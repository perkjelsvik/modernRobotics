function test_mcu_interface_async()
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

    global version_received
    version_received = 0
    % create the interface
    interface = MCUInterface(PACKET_SIZE, MSG_TYPE_FORMAT, messages);
    try
        
        interface.open('/dev/ttyS200', 115200) % open the serial port /dev/ttyS200 at 115200 baudrate.
        % or specify the timeout:
        %int.open('/dev/ttyS200', 115200, 0.0001)
        pause(1.5); % idle for a bit to let Matlab open the serial port.
        interface.register_callback(interface.Type.get_version, @version_callback);
        interface.read_async(true);


        % Write the get_version message
        for i=1:100
            disp(['Sending version for the ' num2str(i) ' time']);
            interface.write_message(interface.Type.get_version);
        end
        while (version_received < 100)
            pause(0.1)
        end
        interface.read_async(false);
        interface.close();
        
        disp('The version callback should have triggered.')
    catch err
        interface.close(); % Also close it if error occur
        rethrow(err)
    end

end
function version_callback(values)
    global version_received
    version_received = version_received + 1
    disp(['Version message received: ' num2str(version_received) ] );
    magic_identifier = values(1)
    firmare_version = values(2:end)
end