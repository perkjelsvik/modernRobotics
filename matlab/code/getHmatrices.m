function [H1_0,H2_0,H3_0] = getHmatrices(q,L)
    uT = getUT();
    H = getInitH(L);
    H4_0 = [eye(3), [0;0;L(1)+L(2)+L(3)]; [0,0,0,1]];
    H1_0 = expm(tilde_twist(uT{1})*q(1));
    H2_0 = H1_0*expm(tilde_twist(uT{2})*q(2))*H{2};
    H3_0 = H2_0*expm(tilde_twist(uT{3})*q(3))*H{3};
end