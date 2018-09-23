# [191211060 - Modern Robotics](https://osiris.utwente.nl/student/OnderwijsCatalogusSelect.do?selectie=cursus&taal=en&collegejaar=2017&cursus=191211060)

This course had a practical assignment where you had to do two exercises with a 3-DOF Robot Arm. This repo is for the practical.

## Course Content
Goal: To give the students a basic knowledge on how to model 3D multi-body systems and control them. The presented techniques are the state of the art on robotics and very powerful tools. They can be used to model, control and analyse complex 3D systems like manipulators, walking machines and flying robots.  

### Topics
Introduction to the field of Robotics
Mathematical Background: Matrix algebra, Intuitive ideas of manifolds, Riemann manifolds, Lie brackets,groups and Lie groups.

### Rigid Body motions 
Rotation representations: Euler angles, Quaternions, SO(3)
Complete motions: SE(3) and introduction to screw theory.
Kinematics: Direct and Inverse kinematics; Differential kinematics: Jacobian

### Dynamics 
Rigid bodies dynamics; 3D springs and Remote center of stiffness; Dissipation of free energy
Dynamics of a mechanism in Lagrangian terms

### Robot Control 
Trajectory Generators; Position and Force Control; Control of Interaction  

## Practical
For the first exercise, the focus was on the kinematics of the robot arm. We needed to find proper unit twists, reference configurations, and an expression for the Jacobian of the robot. 

For the second exercise, we would derive a control law for the robot based on the first exercise. This control law was then tested on a simulated version of the robot in Matlab as well as a physical robot arm. 
