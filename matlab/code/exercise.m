%% init
clc
clear variables

%% Exercise 1 - Part 1
%L_1 = 5;
%L_2 = 12.5; 
%L_3 = 12.5;
L_1 = 0.25;
L_2 = 0.75; 
L_3 = 0.75;

q = [0 pi/2 0]';
L = [L_1 L_2 L_3];

[H1_0,H2_0,H3_0] = getHmatrices(q,L);
H_n_0 = {H1_0,H2_0,H3_0};
H_n_0{:};

J = getJacobian(q,L);
J{:};

%% Exercise 2 - Part 2
P_set = [0 0.75 1]';
q_set_dot = calculate_qd(q,P_set,L);