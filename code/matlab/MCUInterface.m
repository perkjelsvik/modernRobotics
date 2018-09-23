% MCUInterface An interface to communicate to a MCU through a serial port.
%
% The communication protocol is assumed to be fixed length and is expected to
% have a message type to identify the type of message at the start of each
% message.
%
% Throughout the documentation 'int' is used as if it is the object of this
% class, so:
%
%  Packet specification.
%    PACKET_SIZE = 16;  % packet length
%    MSG_TYPE_FORMAT = 'H';
%    messages = {...
%                {1, 'set_joints_position_speed', 'hhhhhhh'}, ...
%                {2, 'get_joints_position_speed', 'hhhhhhh'}, ...
%                {3, 'get_status', 'IH'}, ...
%                {4, 'get_version', 'BB'}, ...
%                }
%   int = MCUInterface(PACKET_SIZE, MSG_TYPE_FORMAT, messages);
%
% This creates an Interface object that expects the message type to be 'H'
% , the message length to be 16 and registers four messages:
%
%   Msg with type 1, name 'set_joints_position_speed', format 'hhhhhh'.
%   Msg with type 2, name 'get_joints_position_speed', format 'hhhhhh'.
%   Msg with type 3, name 'get_status', format 'IH'.
%   Msg with type 4, name 'get_version', format 'BB'.
%
% int.Type.*name* can be used to look up message ids:
%     int.Type.get_status == 3
%
% MCUInterface Methods:
%    open(serial_port, baudrate) - Open this serial port at this baudrate.
%    close() - Disable asynchronous callbacks and close the serial port.
%    [type, values] = read_message() - read a message from the MCU.
%    write_message(type, values) - write a message to the MCU.
%    register_callback(type, fun) - Register a callback function for message type.
%    read_async(state) - Enable or disable asynchronous reading.
%    write_async(state) - Enable or disable asynchronous writing.
%
% MIT License Copyright (c) 2016 Ivor Wanders.



%
% The MIT License (MIT)
%
% Copyright (c) 2016 Ivor Wanders
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
classdef MCUInterface < handle
    properties (Access=private)
        PACKET_SIZE;

        serial % The serial port that is used to communicate to the device.
        have_opened_serial = false;

        read_async_enabled; % Do we read the bytes if they are available?

        % For the messages:
        type_packer; % function to pack the type.
        type_unpacker; % function to unpack the type.
        message_unpacker = {}; % functions to unpack values for each type.
        message_packer = {}; % functions to pack values for each type.
        message_callbacks = {}; % Callbacks that are registered for each type.
    end

    % Do not allow writing on the Type object, but allow access
    properties (SetAccess=private, GetAccess=public)
        Type;
    end

    methods (Access=protected)
        % Async write causes an error if another async write is in progress...
        % So this is kinda useless.
        %~ function serial_write_async(obj, data)
            %~ fwrite(obj.serial, data, 'async')
        %~ end

        function serial_write(obj, data)
            fwrite(obj.serial, data)
        end

        function [data] = read_data(obj)
            % int.read_data() Read bytes from the serial port, always reads PACKET_SIZE length.
            % Matlab reads doubles from the serial port by default, so cast those.
            data = uint8(obj.serial.fread());
        end

        function [type, res] = process_message(obj, data)
            % int.process_message(data) Process a message, unpacking it into its type and values.
            % According to the known message unpacker for this type, it is unknown bytes themselves are returned.
            type = obj.type_unpacker(data);
            if ((type < size(obj.message_unpacker, 2)+1) && (~isempty(obj.message_unpacker{type})))
                a = obj.message_unpacker{type};
                res = a(data(3:end));
            else
                res = double(data(3:end));
            end
        end


        function incoming_message(obj, ser, event)
            % Internal method in case bytes are incoming.
            if obj.read_async_enabled
                [type, values] = obj.read_message();
            end
        end

    end

    methods
        function obj = MCUInterface(packet_size, type_format, messages)
            % int = MCUInterface(packet_size, type_format, messages)
            % 
            % packet_size: an integer that determines the fixed length of packets.
            % type_format: A fmt string according to cStruct.format, usually 'H' or 'B'.
            % messages: A cell array holding {message_type, message_name, message_value_fmt} for each message.
            % 
            % No message may bear message_type == 0, this causes an error because
            % matlab is 1 indexed.
            
            % In matlab we have to call all superclass constructors by hand:
            obj = obj@handle();

            obj.PACKET_SIZE = packet_size;
            obj.serial = 0;
            obj.read_async_enabled = false;

            % Set the type unpacker and packer.
            obj.type_unpacker = cStruct.unpacker(type_format);
            obj.type_packer = cStruct.packer(type_format);

            % Process the messages so that we have the unpack and pack functions.
            for i=1:size(messages, 2)
                if (~isempty(messages{i}))
                    z = messages{i};
                    msg_type_id = z{1};
                    msg_type_name = z{2};
                    msg_fmt = z{3};
                    obj.message_unpacker{msg_type_id} = cStruct.unpacker(msg_fmt);
                    obj.message_packer{msg_type_id} =  cStruct.packer(msg_fmt);
                    obj.Type = setfield(obj.Type, msg_type_name, msg_type_id);
                end
            end
        end

        function [r] = open(obj, port, baudrate, varargin)
            % int.open('COM0', 9600[, timeout=0.1s]) Open the serial port 'COM0', at a baudrate of 9600.
            %
            % Returns true if opening was succesful.
            %
            % For windows, this is usually 'COM1' or 'COM#'.
            % For linux, be sure that the com port is available as /dev/ttyS##.
            % and use that to connect.

            % Handle optional timeout argument.
            if (nargin > 3)
                timeout = varargin{1};
            else
                timeout = 0.1;
            end

            obj.serial = serial(port);
            obj.have_opened_serial = true;
            obj.serial.BaudRate = baudrate;
            obj.serial.BytesAvailableFcnCount = obj.PACKET_SIZE;
            obj.serial.InputBufferSize = obj.PACKET_SIZE;
            %~ obj.serial.Timeout = obj.PACKET_SIZE * 1/obj.serial.BaudRate * 10;
            obj.serial.Timeout = timeout;

            obj.serial.BytesAvailableFcnMode = 'byte';
            %~ obj.serial.BytesAvailableFcn = @obj.incoming_bytes;
            obj.serial.ReadAsyncMode = 'continuous';
            % This event is ALWAYS triggered but the data is not read from
            % the buffer.

            fopen(obj.serial); % actually open it
            % Check if the state is changed to open, indicating succesful opening.
            r = strcmp(obj.serial.Status, 'open');
        end

        function read_async(obj, state)
            % int.read_async(true) Enables asynchronous reading, false disables.
            obj.read_async_enabled = state;
            if (state)
                obj.serial.BytesAvailableFcn = @obj.incoming_message;
            else
                obj.serial.BytesAvailableFcn = '';
            end
        end

        function close(obj)
            % int.close() Gracefully close the serial port.
            %
            % If async is enabled, using this method to close the interface is
            % required to prevent a locked up serial port (unless you restart matlab).
            obj.read_async(false);
            delete(obj)
        end

        function register_callback(obj, type, fun)
            % int.register_callback(type, fun) register a callback to be called when a certain message is received.
            % The function receive one argument: The values received in the message.
            % These functions are always called, regardless of whether read_async is on.
            obj.message_callbacks{type} = fun;
        end

        function [type, values] = read_message(obj)
            % [type values] = int.read_message() Reads a message from the MCU, returning the message type and values.
            % In case of a failure to read type will be equal to zero and values will be empty.
            
            data = obj.read_data();
            if (isempty(data))
                % uhoh, a timeout or read failure occured.
                % Timeout already causes a warning, prevent a hard error.
                type = 0;
                values = [];
                return
            end
            
            [type values] = obj.process_message(data);

            if (type ~= 0)
                if ((type < size(obj.message_callbacks, 2)+1) && (~isempty(obj.message_callbacks{type})))
                    f = obj.message_callbacks{type};
                    f(values);
                end
            end
        end

        function write_message(obj, type, varargin)
            % int.write_message(type[, values]) Write a message of this type with these values to the MCU.
            % If values is not provided an empty array is used during message construction.

            if (nargin > 2)
                values = varargin{1};
            else
                values = [];
            end
            % Allocate an empty message
            d = uint8(zeros(1, obj.PACKET_SIZE));

            % Set the type at the start
            type_bytes = obj.type_packer(type);
            d(1:size(type_bytes,2)) = type_bytes;

            % Check if we have a message packer and pack the values into the message.
            if ((type < size(obj.message_packer, 2)+1) && (~isempty(obj.message_packer{type})))
                a = obj.message_packer{type};
                res = a(values);
            else
                res = [];
            end
            d(size(type_bytes, 2)+1:size(type_bytes, 2)+size(res,2)) = res;

            % Write it to the serial port.
            obj.serial_write(d);
        end

        function delete(obj)
            % This is the destructor.
            %disp('Destructing MCUInterface.')
            if (obj.have_opened_serial)
                stopasync(obj.serial);
                fclose(obj.serial)
                delete(obj.serial)
                clear obj.serial
            end
        end

    end
end