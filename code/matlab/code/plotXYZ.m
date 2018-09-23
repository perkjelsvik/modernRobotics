function plotXYZ(xyz_set, xyz, xyz_robot)
figure(1)
plot(xyz_set(1,85:241),xyz_set(3,85:241),'--','LineWidth',3); hold on;
plot(xyz(1,85:241),xyz_set(3,85:241),'b','LineWidth',2); grid on;
plot(xyz_robot(1,85:241),xyz_robot(3,85:241),'r','LineWidth',2); hold off;
xlabel('X [cm]', 'FontSize', 16);ylabel('Z [cm]', 'FontSize', 16);
legend({'XZ_{set}', 'XZ_{sim}','XZ_{rob}'}, ...
    'FontSize', 26, 'Location', 'best');
title('Position plot of robot arm in XZ-plane', 'FontSize', 24)

figure(2)
plot(1:500,xyz(1,:)-xyz_set(1,:),...
    'LineWidth',2); grid on; hold on;
plot(1:500,xyz_robot(1,:)-xyz_set(1,:),...
    'LineWidth',2);
plot(1:500,zeros(1,500),'k'); hold off;
xlabel('t', 'FontSize', 16);ylabel('X_{error} [cm]', 'FontSize', 16);
legend({ 'X_{sim}','X_{rob}'}, ...
    'FontSize', 26, 'Location', 'best');
title('Error plot of X', 'FontSize', 24)

figure(3)
plot(1:500,xyz(3,:)-xyz_set(3,:),...
    'LineWidth',2); grid on; hold on;
plot(1:500,xyz_robot(3,:)-xyz_set(3,:),...
    'LineWidth',2);
plot(1:500,zeros(1,500),'k'); hold off;
xlabel('t', 'FontSize', 16);ylabel('Z_{error} [cm]', 'FontSize', 16);
legend({'Z_{sim}','Z_{rob}'}, ...
    'FontSize', 26, 'Location', 'best');
title('Error plot of Z', 'FontSize', 24)
end