%% Settings and parameters
clc
clear all
    
addpath('code');

% Is the real robot connected?
realRobotOutput = true;
plotRobot = false;
% Serial port for robot: find out what name the port has
%com_port = '/dev/tty.usbmodem1421'; % UNIX example
com_port = 'COM4'; % Windows example

%
% Better not change the settings below
%

% ROBOT PARAMETERS
l1 = 5;
l2 = 12.5;
l3 = 12.5;
robot_params=[l1 l2 l3];

% control loop parameters
T = 0.04;
t_end = 20;


%% Connect to robot
% do not change this section
if realRobotOutput
    % Create the arm and connect to it
    arm = ArmInterface();
    res = arm.open(com_port);
    pause(1.5) % Give matlab the time to open the serial port.

    % Retrieve the arm firmware version and print it.
    v = arm.get_version();
    disp(['Arm firmware version: ' num2str(v(1)) '.' num2str(v(2))])
    pause(2)
end

%% Initialise
% Do not change this section, unless you change the trajectory
% Initial values of joint angles
q=[0.0144 0.41 2.3 ]';
%q=[0 0 0]';

if realRobotOutput
    % Slowly move to starting position
    qstart = arm.get_q()';
    for i=1:50
        arm.set_q(qstart + (q-qstart)*i/50);
        pause(0.04);
    end
end
%% Control loop
t = 0;
N = round(t_end / T);
q_robot = [0,0,0];
q_robot_old = [0,0,0];

qd = [0;0;0];
xyz_set = zeros(3,N);
xyz = zeros(3,N);
xyz_robot = zeros(3,N);
tic
for i=1:N
    % while loop to wait for timing
	while toc < T
	end
    dt = toc;     % Real loop time
    tic           % reset timer
    t = t + dt;   % save time (real time of the loop)
    
    % Euler integration of angles
    q = q + dt*qd;
 
    % Move the real robot
    if realRobotOutput
        arm.set_q(q);
    end
    
    %if mod(i,50)==1
    	% Generate setpoint
        x = 8*cos(1*t);
        y = -15;
        z = 8+ 6*sin(2*t);
    %end
    
    setpoint=[x;y;z];
    xyz_set(:,i) = setpoint;
    
    % Calculate desired angle speeds
    qd = calculate_qd(q, setpoint, robot_params);
    
    % Calculate all the frames of the real robot
    if realRobotOutput
        [q_robot_new, succes]= arm.get_q(); % Get robot position
            if succes
                q_robot_old=q_robot;
                q_robot=q_robot_new;
            else
                q_robot=q_robot_old;
            end
    else
        q_robot = [0,0,0];
    end
    
    %q = [i*0.2 0 0];
    %q_robot = [i*0.2 0 0];
    
    [H1_0, H2_0, H3_0] = getHmatrices(q, robot_params);
    [rH1_0, rH2_0, rH3_0] = getHmatrices(q_robot,robot_params);
    xyz(:,i) = H3_0(1:3,4);
    xyz_robot(:,i) = rH3_0(1:3,4);
    
    % Plot the robot
    if plotRobot
        plot_robot3(x,y,z,H1_0,H2_0,H3_0,rH1_0,rH2_0,rH3_0);
    end
   
end

%% De-init
pause(0.5)
if realRobotOutput
    % Slowly move to starting position
    qstart = arm.get_q();
    for i=1:50
        arm.set_q(qstart*(1-i/50));
        pause(0.04);
    end
end