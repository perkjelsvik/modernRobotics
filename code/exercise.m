%% init
close all
clc
clear variables

%% Exercise 1 - Part 1
L_1 = 0.25;
L_2 = 0.75; 
L_3 = 0.75;

H_1_0 = [eye(3), [0;0;0]; [0,0,0,1]];
H_2_1 = [eye(3), [0;0; -L_1]; [0,0,0,1]];
H_3_2 = [eye(3), [0;0; -L_2]; [0,0,0,1]];
H_ee_0 = [eye(3), [0;0; -L_3]; [0,0,0,1]];

q = [0 0 0 0]';
L = [L_1; L_2; L_3];

H_n_0 = getHmatrices(q, L);
%H_n_0{:}

J = getJacobian(q,L);
J{:}

function H_n_0 = getHmatrices(q,L)
    uT = {...
        [0;0;-1;0;0;0]; ...
        [-1;0;0;0;L(1);0]; ...
        [-1;0;0;0;L(2);0]; ...
        [0;0;0;0;0;0]   };
    H_1_0 = [eye(3), [0;0;0]; [0,0,0,1]];
    H_2_1 = [eye(3), [0;0; -L(1)]; [0,0,0,1]];
    H_3_2 = [eye(3), [0;0; -L(2)]; [0,0,0,1]];
    H_ee_3 = [eye(3), [0;0; -L(3)]; [0,0,0,1]];
    H = {H_1_0; H_2_1; H_3_2; H_ee_3};
    
    H_n_0{1} = expm(tilde_twist(uT{1})*q(1))*H{1};
    H_n_0{2} = H_n_0{1}*expm(tilde_twist(uT{2})*q(2))*H{2};
    H_n_0{3} = H_n_0{2}*expm(tilde_twist(uT{3})*q(3))*H{3};
    H_n_0{4} = H_n_0{3}*expm(tilde_twist(uT{4})*1)*H{4};
end

function J = getJacobian(q,L)
    uT = {...
        [0;0;-1;0;0;0]; ...
        [-1;0;0;0;L(1);0]; ...
        [-1;0;0;0;L(2);0]; ...
        [0;0;0;0;0;0]   };
    H = getHmatrices(q,L);
    H_n_0(2:5) = H;
    H_n_0{1} = eye(4);
    for i=1:length(H_n_0)-1
        R = H_n_0{i}(1:3,1:3);
        p_tilde = tilde_3(H_n_0{i}(1:3,4));
        adj = [R zeros(3); p_tilde*R R]
        J{i} = adj*uT{i};
    end
end

function Twist = tilde_twist(T)
    omega = tilde_3(T(1:3));
    Twist = [omega, T(4:6); [0 0 0 0]];
end

function X = tilde_3(x)
    X =[0 -x(3) x(2) ; x(3) 0 -x(1) ; -x(2) x(1) 0 ];
end