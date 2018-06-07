function J = getJacobian(q,L)
    uT = {...
        [0;0;-1;0;0;0]; ...
        [-1;0;0;0;L(1);0]; ...
        [-1;0;0;0;L(2);0]; ...
        [0;0;0;0;0;0]; ...
        [0;0;0;0;0;0]};
    H = getHmatrices(q,L);
    H_n_0(2:6) = H;
    H_n_0{1} = eye(4);
    for i=1:length(H_n_0)-1
        R = H_n_0{i}(1:3,1:3);
        p_tilde = tilde_3(H_n_0{i}(1:3,4));
        Adj = [R zeros(3); p_tilde*R R];
        J{i} = Adj*uT{i};
    end
end