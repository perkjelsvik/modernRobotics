function Twist = tilde_twist(T)
    omega = tilde_3(T(1:3));
    Twist = [omega, T(4:6); [0 0 0 0]];
end