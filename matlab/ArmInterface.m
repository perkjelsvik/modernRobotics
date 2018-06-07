% ArmInterface The interface for the RAM 3 segment serial link robot arm.
%
% Throughout the documentation 'arm' is used as if it is the object of this
% class, so:
%
%   arm = ArmInterface();
%
% ArmInterface Properties:
%    version - Holds the firmware version of the robot arm.
%
% ArmInterface Methods:
%    open - Open this serial port.
%    get_version - Return the version of the firmware in the arm.
%    get_status - Return status information from the arm.
%    set_position - Set the setpoint of the joints, moving at default speed.
%    get_position - Return the a vector of joint positions.
%    set_default_speed - Set the default movement speed.
%    get_default_speed - Get the default movement speed.
%    set_position_speed - Set the setpoints and specify speed per joint.
%    get_position_speed - Return both the joint positions and speeds.
%    set_q - Sets the robot's joint positions as specified.
%    get_q - Gets the robot's joint positions.
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
classdef ArmInterface < MCUInterface
    properties
        version; % Hold the retrieved version in the object.
    end
    properties (SetAccess = immutable, Constant = true)
        JOINTS = 3;


        % Communication with the MCU is governed by just these variables:
        SERIAL_BAUDRATE = 115200; % the baudrate.
        SERIAL_TIMEOUT = 0.1;
        PACKET_SIZE = 16;  % packet length
        MSG_TYPE_FORMAT = 'H';
        VERSION_MAGIC_IDENTIFIER = 1182471;
        messages = {...
                    {1, 'set_joints_position_speed', 'hhhhhh'}, ...
                    {2, 'get_joints_position_speed', 'hhhhhh'}, ...
                    {3, 'get_status', 'IH'}, ...
                    {4, 'get_version', 'IBB'}, ...
                    }
    end
    properties (Access=private)
        move_speed_default = 100;
    end
    
    methods(Static)
        function [s] = get_serial_ports()
            % ArmInterface.get_serial_ports() - Returns a list of available serial ports.
            % Use this command with the arm without the arm connected and with it connected.
            % The serial port that appears in the list is the one to control the robot arm.
            a = instrhwinfo('serial');
            s = a.AvailableSerialPorts;
        end
    end

    methods
        function obj = ArmInterface()
            obj = obj@MCUInterface(ArmInterface.PACKET_SIZE, ArmInterface.MSG_TYPE_FORMAT, ArmInterface.messages);
        end

        function [r] = open(obj, serialport)
            r = obj.open@MCUInterface(serialport, ArmInterface.SERIAL_BAUDRATE, ArmInterface.SERIAL_TIMEOUT);
        end


        function [v] = get_version(obj)
            % v = arm.get_version() Retrieve the firmware version.
            %
            % This returns a vector of the major and minor version in the firmware.
            % In case it fails to retrieve the version an error is raised.

            obj.write_message(obj.Type.get_version);
            [type data] = obj.read_message();
            if (type == obj.Type.get_version)
                if (obj.VERSION_MAGIC_IDENTIFIER == data(1))
                    v = data(2:end);
                else
                    error('This serial port is not one associated with the robot arm.')
                end
            else
                error('Reading version failed.')
            end
        end

        function [uptime transmission_errors] = get_status(obj)
            % [uptime transmission_errors] = arm.get_status() Get the status of the arm.
            %
            % Returns the uptime in milliseconds sinds microcontroller reset and
            % the number of transmission errors that occured.
            obj.write_message(obj.Type.get_status);
            [type data] = obj.read_message();
            if (type == obj.Type.get_status)
                uptime = data(1);
                transmission_errors = data(2);
            else
                error('Reading status failed.')
            end
        end

        function set_position_speed(obj, position, speed)
            % arm.set_position_speed(position, speed) Move to positions at a speed.
            %
            % Positions should be a vector of arm.JOINTS length, these are the raw positions as sent to the servos.
            % Speed should be a vector of arm.JOINTS length, these are the raw speeds as sent to the servos.
            % This function raises an error if the dimensions of the position or speed vector is not correct.
            if (size(position) ~= [1 obj.JOINTS])
                error(['Position should be size [1 ' num2str(obj.JOINTS) '].'])
            end
            if (size(speed) ~= [1 obj.JOINTS])
                error(['Speed should be size [1 ' num2str(obj.JOINTS) '].'])
            end

            values = [position; speed];
            values = reshape(values, [1, 2*obj.JOINTS]);
            obj.write_message(obj.Type.set_joints_position_speed, values);
        end

        function set_position(obj, positions)
            % arm.set_position(position) Move to positions at default speed.
            %
            % Positions should be a vector of arm.JOINTS length, these are the raw positions as sent to the servos.
            % This function raises an error if the dimensions of the position or speed vector is not correct.
            obj.set_position_speed(positions, ones(1, obj.JOINTS) * obj.move_speed_default);
        end

        function [position speed] = get_position_speed(obj)
            % [position speed] = arm.get_position_speed() Retrieve current position and speed.
            %
            % position is a vector of arm.JOINTS elements with the current position.
            % speed is a vector of arm.JOINTS elements with the current speed.
            % This function raises an error if the values could not be read.

            obj.write_message(obj.Type.get_joints_position_speed);
            [type data] = obj.read_message();
            if (type == obj.Type.get_joints_position_speed)
                values = reshape(data, [2, obj.JOINTS]);
                position = values(1, :);
                speed = values(2, :);
            else
                error('Reading position and speeds failed.')
            end
            
        end

        function [position] = get_position(obj)
            % [position] = arm.get_position() Retrieve current position.
            %
            % position is a vector of arm.JOINTS elements with the current position.
            % This function raises an error if the values could not be read.
            [position discarded_value] = obj.get_position_speed();
        end

        function set_default_speed(obj, speed)
            % arm.set_default_speed(speed) Sets the default movement speed for all joints.
            %
            % Use this speed for each joint if set_position() is used.
            obj.move_speed_default = speed;
        end

        function [speed] = get_default_speed(obj)
            % speed = arm.get_default_speed() Get the default movement speed.
            %
            % Return the current movement speed configured as default.
            speed = obj.move_speed_default;
        end

        function set_q(obj, q)
            % arm.set_q(q) - Sets the joint positions to the specified vector.
            %
            %   q(1) The first joint \in [-2.618 2.618]
            %   q(2) The second joint \in [-pi/2 pi/2]
            %   q(3) The third joint \in [-2.618, 2.618]
            q1 = round(((min(max(q(1), -2.618), 2.6180) + 2.618)/5.2360)*1022 + 1);
            q2 = round(((min(max(-q(2), -pi/2), pi/2) + pi/2)/pi)*614.4 + 205);
            q3 = round(((min(max(q(3), -2.618), 2.6180) + 2.618)/5.2360)*1022 + 1);
            obj.set_position([q1, q2, q3]);
        end

        function [q, res] = get_q(obj, q)
            % [q is_success] arm.get_q() - Gets the joint positions.
            %
            %   Is_success is true if positions were retrieved sucessfully, if
            %   they were not, it will be false and the value of q must not be
            %   used.
            %   q will be a vector of three joint coordinates.
            res = true;
            q = [0 0 0];
            try
                pos = double(obj.get_position());
            catch me
                res = false;
                warning(me.message);
                return;
            end
            if (any(pos < 0))
                res = false;
            end
            q(1) = ((pos(1) - 512)/1024) * (600 / 360) * pi;
            q(2) = -((pos(2) - 512)/1024) * (600 / 360) * pi;
            q(3) = ((pos(3) - 512)/1024) * (600 / 360) * pi;
        end
    end
end