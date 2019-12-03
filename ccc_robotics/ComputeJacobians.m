function [uvms] = ComputeJacobians(uvms)
% compute the relevant Jacobians here
% joint limits
% manipulability
% tool-frame position control
% vehicle-frame position control
% horizontal attitude 
% minimum altitude
% preferred arm posture ( [-0.0031 1.2586 0.0128 -1.2460] )
%
% remember: the control vector is:
% [q_dot; p_dot] 
% [qdot_1, qdot_2, ..., qdot_7, xdot, ydot, zdot, omega_x, omega_y, omega_z]
%
% therefore all task jacobians should be of dimensions
% m x 13
% where m is the row dimension of the task, and of its reference rate

% compute manipulability Jacobian
[Jmu_a, uvms.mu] = ComputeManipulability(uvms.bJe, uvms.djdq);
uvms.Jmu = [Jmu_a zeros(1,6)];

% computation for tool-frame Jacobian
% [omegax_t omegay_t omegaz_t xdot_t ydot_t zdot_t] = Jt ydot
% [angular velocities; linear velocities]
%
% Ste is the rigid body transformation from vehicle-frame to end-effector
% frame projected on <v>
uvms.Ste = [eye(3) zeros(3);  -skew(uvms.vTe(1:3,1:3)*uvms.eTt(1:3,4)) eye(3)];
% uvms.bJe contains the arm end-effector Jacobian (6x7) wrt arm base
% top three rows are angular velocities, bottom three linear velocities
uvms.Jt_a  = uvms.Ste * [uvms.vTb(1:3,1:3) zeros(3,3); zeros(3,3) uvms.vTb(1:3,1:3)] * uvms.bJe;
% vehicle contribution is simply a rigid body transformation from vehicle
% frame to tool frame. Notice that linear and angular velocities are
% swapped due to the different definitions of the task and control
% variables
uvms.Jt_v = [zeros(3) eye(3); eye(3) -skew(uvms.vTt(1:3,4))];
% juxtapose the two Jacobians to obtain the global one
uvms.Jt = [uvms.Jt_a uvms.Jt_v];

% horizontal attitude Jacobian
kv   = [0 0 1]';
w_kw = [0 0 1]';
v_kw = (uvms.wTv(1:3,1:3))' * w_kw;
uvms.phi   = ReducedVersorLemma(v_kw, kv);
if (norm(uvms.phi) > 0)
    nphi = uvms.phi/norm(uvms.phi);
else
    nphi = [0 0 0]';
end
uvms.Jha = [zeros(1,7) nphi'*[zeros(3) eye(3)]];

% Position-control
wRv = uvms.wTv(1:3,1:3); % world_Rotation_vehicle
uvms.Jposc = [zeros(3,7) wRv zeros(3,3);zeros(3,7) zeros(3,3) wRv];

% Minimum Altitude Control from sea floor 
uvms.Jmac = [zeros(3,7) wRv zeros(3,3);zeros(3,7) zeros(3,3) zeros(3,3)];

end