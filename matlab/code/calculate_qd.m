function q_set_dot = calculate_qd(q,P_set,L)
    [H1_0,H2_0,H3_0] = getHmatrices(q,L);
    H_n_0 = {H1_0,H2_0,H3_0};
    J = getJacobian(q,L);
    
    Kv = 20;
    P_ee = H_n_0{3}(1:3,4);
    P_ee_dot = Kv*(P_set-P_ee); 
    if norm(P_ee_dot)>10
        P_ee_dot = 10*(P_ee_dot/norm(P_ee_dot));
    end
    
    H_0_4 = [eye(3), -H_n_0{3}(1:3,4); [0,0,0,1]];
    Ad_H_0_4 = [...
                H_0_4(1:3,1:3),             zeros(3); ...
    tilde_3(H_0_4(1:3,4))*H_0_4(1:3,1:3),   H_0_4(1:3,1:3)];
    
    J_prime = cell(size(J));
    for i=1:length(J)
        J_prime{i} = Ad_H_0_4*J{i};
    end
    J_v = [J_prime{1}(4:6), J_prime{2}(4:6), J_prime{3}(4:6)];
    q_set_dot = pinv(J_v)*P_ee_dot;
end