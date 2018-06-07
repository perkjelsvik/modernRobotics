%% init
close all
clc
clear variables

%% Exercise 1 - Part 1
L_1 = 0.25;
L_2 = 0.75; 
L_3 = 0.75;

q = [0 0 0 0]';
L = [L_1; L_2; L_3];

H_n_0 = getHmatrices(q, L);
H_n_0{:};

J = getJacobian(q,L);
J{:};

%% Exercise 2 - Part 2
P_sp = [1; 1; -1];
Kv = 1;
P_ee = H_n_0{4}(1:3,4);
P_ee_dot = Kv*(P_sp-P_ee);  
H_0_4 = [...
    H_n_0{5}(1:3,1:3)', -H_n_0{5}(1:3,1:3)*H_n_0{5}(1:3,4); [0,0,0,1]];
Ad_H_0_4 = [...
    H_0_4(1:3,1:3), zeros(3); ...
    tilde_3(H_0_4(1:3,4))*H_0_4(1:3,1:3), H_0_4(1:3,1:3)];
T_3_0_4 = Ad_H_0_4*J{3};
J_prime = cell(size(J));
for i=1:length(J)
        J_prime{i} = Ad_H_0_4*J{i};
end