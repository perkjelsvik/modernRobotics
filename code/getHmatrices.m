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