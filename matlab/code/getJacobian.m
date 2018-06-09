function J = getJacobian(q,L)
    uT = getUT();
    [H1_0,H2_0,H3_0] = getHmatrices(q,L);
    H_n_0 = {H1_0,H2_0,H3_0};
    J = cell(1,size(H_n_0,2));
    J{1} = uT{1};
    
    for i=2:length(H_n_0)
        R = H_n_0{i-1}(1:3,1:3);
        p_tilde = tilde_3(H_n_0{i-1}(1:3,4));
        Adj = [R zeros(3); p_tilde*R R];
        J{i} = Adj*uT{i};
    end
end