function [H1_0,H2_0,H3_0] = getHmatrices(q,L)
    uT = getUT();
    H = getInitH(L);
    H1_0 = expm(tilde_twist(uT{1})*q(1))*H{1};
    H2_0 = H1_0*expm(tilde_twist(uT{2})*q(2))*H{2};
    H3_0 = H2_0*expm(tilde_twist(uT{3})*q(3))*H{3};
end