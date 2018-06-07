%% Init
clear all;
% Create the arm and connect to it
arm = ArmInterface();
res = arm.open('/dev/tty.usbmodem1421');
pause(1.5) % Give matlab the time to open the serial port.

% Retrieve the arm firmware version and print it.
v = arm.get_version();
disp(['Arm firmware version: ' num2str(v(1)) '.' num2str(v(2))])
pause(2)

%% Move somewhere
q0 = [450 500 550];
arm.set_position(q0);

%% Measure
N = 2000;
q = zeros(3,N);
dq = zeros(3,N);
fprintf('Starting to execute %i measurements..\n',N);
now_at = 0;
for i=1:N
    arm.set_position(q0 + 50*sin(i/N*2*pi*1));
    pause(0.001);
    if(floor(10*i/N) ~= now_at)
        now_at = floor(10*i/N);
        fprintf('%g%%..',10*now_at)
    end
    [pos speed] =arm.get_position_speed();
    dq(:,i) = speed;
    q(:,i) = pos;
end
fprintf('Done!\n')

%% Plot results
figure(1)
i=1:N;
plot(i,q(1,:),'x',i,q(2,:),'x',i,q(3,:),'x');
legend('q1','q2','q3');
xlabel('sample');
ylabel('pos')

figure(2)
i=1:N;
plot(i,dq(1,:),'x',i,dq(2,:),'x',i,dq(3,:),'x');
legend('dq1','dq2','dq3');
xlabel('sample');
ylabel('speed')

%% Statistics
success_rate = sum(q>350,2) / N;

fprintf('Success rate for each joint: (%g,%g,%g)\n',success_rate)
fprintf('(failure: %g%%,%g%%,%g%%)\n',100-100*success_rate);

%% Finish

arm.close();