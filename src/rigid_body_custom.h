#ifndef RIGID_BODY_CUSTOM_H
#define RIGID_BODY_CUSTOM_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/box_shape3d.hpp>
#include <godot_cpp/classes/sphere_shape3d.hpp>
#include <godot_cpp/classes/shape3d.hpp>
#include <godot_cpp/classes/collision_shape3d.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/core/memory.hpp>
#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/box_mesh.hpp>
#include <godot_cpp/classes/sphere_mesh.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/classes/collision_object3d.hpp>
#include <godot_cpp/classes/physics_body3d.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/classes/engine.hpp>


//#include "physics_handler.h"


namespace godot {

    class PhysicsHandler;

class RigidBodyCustom : public Node3D {
    GDCLASS(RigidBodyCustom, Node3D)

private:
    PhysicsServer3D *physics_server;
    RID body_rid;
    RID mesh_rid;

    CollisionShape3D *collision_shape;
    MeshInstance3D *mesh_instance;

    Transform3D body_trans;

    Vector3 velocity;
   // Vector3 old_velocity;

    bool gravity_enabled;
    
    Vector3 forces;

    Vector3 center_of_mass_local; // relative to body origin
    Vector3 center_of_mass_global; // COM position in global/world coordinates

    // get and set center of mass
    void set_center_of_mass_local(const Vector3& p_center_of_mass);


    float mass;
    float inverse_mass;
    float restitution; // for bounciness, eg the elasticity of the object
    Vector3 gravity;

    // new variables to support angular motion/acceleration angular impulse
    Vector3 angular_velocity;
    Vector3 torque;

    Basis inertia_tensor;
    Basis inverse_inertia_tensor;

    //Basis world_inertia_tensor;
    Basis inverse_world_inertia_tensor;

    void update_world_inertia_tensor();




    Vector3 position;
    Vector3 old_position;

    


protected:



    static void _bind_methods();

    

public:
    RigidBodyCustom();
    ~RigidBodyCustom();

    void _enter_tree() override;
    void _exit_tree() override;


    Vector3 get_center_of_mass_local() const;
    Vector3 get_center_of_mass_global() const; 

    Vector3 old_velocity;

    void _process(double delta) override;
    void _ready() override;

    void set_trans(const Transform3D &new_trans);
    Transform3D get_trans() const;



    

    

    // DEBUG DRAWING
    

    // angular 
    void set_angular_velocity(const Vector3& p_angular_velocity);
    Vector3 get_angular_velocity() const;
    void apply_torque(const Vector3& p_torque);
    void apply_impulse_off_centre(const Vector3& impulse, const Vector3& rel_pos); // applying impulse off-centre
    void correct_position(const Vector3& correction);
    void correct_orientation(const Basis& correction);
    void update_inertia_tensor();

    RID get_body_rid() const;
    void update_server_transforms();
    void integrate_forces(double delta_time);

    void apply_force(const Vector3 &force); // help accumulate forcoes
    void apply_impulse(const Vector3& impulse); // immediately apply an impulse and velocity change

    Vector3 get_velocity() const;
    void set_velocity(const Vector3 &new_velocity);

    void set_restitution(float new_restitution);
    float get_restitution() const;

    void set_position(const Vector3 &new_position);

    Vector3 get_old_position() const;
    Vector3 get_position() const;
    Vector3 get_gravity() const;
    void set_gravity(const Vector3& p_gravity);

    // get and set mass
    void set_mass(float new_mass);
    float get_mass() const;
    // get inverse mass 
    float get_inv_mass() const;

    // Add to public section:
    const Basis& get_inverse_inertia_tensor() const { return inverse_inertia_tensor; }
    const Basis& get_inverse_world_inertia_tensor() const { return inverse_world_inertia_tensor; }

    // Add new methods
    void set_gravity_enabled(bool p_enabled);
    bool is_gravity_enabled() const;
};

} // namespace godot

#endif // RIGID_BODY_CUSTOM_H
