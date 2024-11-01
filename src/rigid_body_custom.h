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




namespace godot {

    class PhysicsHandler;


/**
 * @brief Custom implementation of a rigid body physics object
 * 
 * RigidBodyCustom provides physics simulation functionality including collision detection,
 * force application, and both linear and angular motion.
 */
class RigidBodyCustom : public Node3D {
    GDCLASS(RigidBodyCustom, Node3D)

private:
    /** @brief Pointer to the physics server instance */
    PhysicsServer3D *physics_server;
    /** @brief Unique identifier for the physics body */
    RID body_rid;
    /** @brief Unique identifier for the mesh */
    RID mesh_rid;

    /** @brief Collision layer this body belongs to */
    uint32_t collision_layer = 1;
    /** @brief Layers this body will collide with */
    uint32_t collision_mask = 1; 

    /** @brief Collision shape component */
    CollisionShape3D *collision_shape;
    /** @brief Visual mesh component */
    MeshInstance3D *mesh_instance;

    /** @brief Current transform of the body */
    Transform3D body_trans;

    /** @brief Current linear velocity */
    Vector3 velocity;

    /** @brief Whether gravity affects this body */
    bool gravity_enabled;
    
    /** @brief Accumulated forces acting on the body */
    Vector3 forces;

    /** @brief Center of mass in local coordinates */
    Vector3 center_of_mass_local;
    /** @brief Center of mass in world coordinates */
    Vector3 center_of_mass_global;

    // get and set center of mass
    void set_center_of_mass_local(const Vector3& p_center_of_mass);


    /** @brief Mass of the rigid body */
    float mass;
    /** @brief Inverse mass (1/mass) for calculations */
    float inverse_mass;
    /** @brief Coefficient of restitution (bounciness) */
    float restitution;
    /** @brief Gravity vector affecting this body */
    Vector3 gravity;

    /** @brief Current angular velocity */
    Vector3 angular_velocity;
    /** @brief Accumulated torque acting on the body */
    Vector3 torque;

   /** @brief Inertia tensor in local coordinates */
    Basis inertia_tensor;
    /** @brief Inverse of the inertia tensor */
    Basis inverse_inertia_tensor;

    /** @brief Inverse of the inertia tensor in world coordinates */
    Basis inverse_world_inertia_tensor;
    Basis world_inertia_tensor;

    /**
     * @brief Updates the world space inertia tensor
     */
    void update_world_inertia_tensor();




    /** @brief Current position */
    Vector3 position;
    /** @brief Position from previous frame */
    Vector3 old_position;

    /** @brief Previous frame's orientation */
    Basis previous_basis;

    


protected:



    static void _bind_methods();

    

public:
    /** @brief Constructor */
    RigidBodyCustom();
    /** @brief Destructor */
    ~RigidBodyCustom();

    


    /** @brief Sets the collision layer value for a specific layer
     *  @param p_layer_number The layer number to modify (1-32)
     *  @param p_value True to enable collision on this layer, false to disable */
    void set_collision_layer_value(int p_layer_number, bool p_value);

    /** @brief Gets the collision layer value for a specific layer
     *  @param p_layer_number The layer number to check (1-32)
     *  @return True if collision is enabled on this layer, false otherwise */
    bool get_collision_layer_value(int p_layer_number) const;

    /** @brief Sets the collision mask value for a specific layer
     *  @param p_layer_number The layer number to modify (1-32)
     *  @param p_value True to enable collision with this layer, false to disable */
    void set_collision_mask_value(int p_layer_number, bool p_value);

    /** @brief Gets the collision mask value for a specific layer
     *  @param p_layer_number The layer number to check (1-32)
     *  @return True if collision with this layer is enabled, false otherwise */
    bool get_collision_mask_value(int p_layer_number) const;

    /** @brief Sets the entire collision layer bitmask
     *  @param p_layer The 32-bit collision layer mask */
    void set_collision_layer(uint32_t p_layer);

    /** @brief Gets the entire collision layer bitmask
     *  @return The current 32-bit collision layer mask */
    uint32_t get_collision_layer() const;

    /** @brief Sets the entire collision mask bitmask
     *  @param p_mask The 32-bit collision mask */
    void set_collision_mask(uint32_t p_mask);

    /** @brief Gets the entire collision mask bitmask
     *  @return The current 32-bit collision mask */
    uint32_t get_collision_mask() const;

    //void _enter_tree() override;
    /** @brief Called when node is removed from the scene tree */
    void _exit_tree() override;

    /** @brief Gets the center of mass in local coordinates
     *  @return The center of mass vector in local space */
    Vector3 get_center_of_mass_local() const;

    /** @brief Gets the center of mass in global coordinates
     *  @return The center of mass vector in world space */
    Vector3 get_center_of_mass_global() const; 

    /** @brief Velocity from the previous physics frame */
    Vector3 old_velocity;

    /** @brief Called every frame for non-physics updates
     *  @param delta Time elapsed since the previous frame */
    void _process(double delta) override;

    /** @brief Called when the node enters the scene tree and becomes active */
    void _ready() override;

    /** @brief Sets the transform of the rigid body
     *  @param new_trans The desired transform matrix */
    void set_trans(const Transform3D &new_trans);

    /** @brief Gets the current transform of the rigid body
     *  @return The current transform matrix */
    Transform3D get_trans() const;

    

  /** @brief Sets the angular velocity of the rigid body
     *  @param p_angular_velocity The desired angular velocity vector */
    void set_angular_velocity(const Vector3& p_angular_velocity);

    /** @brief Gets the current angular velocity of the rigid body
     *  @return The current angular velocity vector */
    Vector3 get_angular_velocity() const;

    /** @brief Applies a torque to the rigid body
     *  @param p_torque The torque vector to apply */
    void apply_torque(const Vector3& p_torque);

    /** @brief Applies an impulse at a point offset from the center of mass
     *  @param impulse The impulse vector to apply
     *  @param rel_pos The position relative to center of mass where impulse is applied */
    void apply_impulse_off_centre(const Vector3& impulse, const Vector3& rel_pos);

    /** @brief Corrects the position of the rigid body (used in collision resolution)
     *  @param correction The position correction vector */
    void correct_position(const Vector3& correction);

    /** @brief Corrects the orientation of the rigid body (used in collision resolution)
     *  @param correction The orientation correction matrix */
    void correct_orientation(const Basis& correction);

    /** @brief Updates the inertia tensor based on current mass and shape */
    void update_inertia_tensor();

    /** @brief Gets the RID (Resource ID) of the physics body
     *  @return The body's RID */
    RID get_body_rid() const;

    /** @brief Updates the physics server with current transforms */
    void update_server_transforms();

    /** @brief Integrates accumulated forces over the given time step
     *  @param delta_time The time step for integration */
    void integrate_forces(double delta_time);

    /** @brief Applies a force to the rigid body (accumulated over time)
     *  @param force The force vector to apply */
    void apply_force(const Vector3 &force);

    /** @brief Applies an instantaneous impulse to the rigid body
     *  @param impulse The impulse vector to apply */
    void apply_impulse(const Vector3& impulse);

    /** @brief Gets the current linear velocity
     *  @return The current velocity vector */
    Vector3 get_velocity() const;

    /** @brief Sets the linear velocity of the rigid body
     *  @param new_velocity The desired velocity vector */
    void set_velocity(const Vector3 &new_velocity);

    /** @brief Sets the coefficient of restitution (bounciness)
     *  @param new_restitution The desired restitution value */
    void set_restitution(float new_restitution);

    /** @brief Gets the current coefficient of restitution
     *  @return The current restitution value */
    float get_restitution() const;

    /** @brief Sets the position of the rigid body
     *  @param new_position The desired position vector */
    void set_position(const Vector3 &new_position);

    /** @brief Gets the position from the previous frame
     *  @return The previous frame's position vector */
    Vector3 get_old_position() const;

    /** @brief Gets the current position
     *  @return The current position vector */
    Vector3 get_position() const;

    /** @brief Gets the current gravity vector affecting this body
     *  @return The gravity vector */
    Vector3 get_gravity() const;

    /** @brief Sets the gravity vector affecting this body
     *  @param p_gravity The desired gravity vector */
    void set_gravity(const Vector3& p_gravity);

   /** @brief Sets the mass of the rigid body
     *  @param new_mass The desired mass value in kilograms */
    void set_mass(float new_mass);

    /** @brief Gets the current mass of the rigid body
     *  @return The current mass in kilograms */
    float get_mass() const;

    /** @brief Gets the inverse mass (1/mass) of the rigid body
     *  @return The inverse mass value */
    float get_inv_mass() const;

    /** @brief Gets the inverse inertia tensor in local coordinates
     *  @return Reference to the inverse inertia tensor matrix */
    const Basis& get_inverse_inertia_tensor() const { return inverse_inertia_tensor; }

    /** @brief Gets the inverse inertia tensor in world coordinates
     *  @return Reference to the world space inverse inertia tensor matrix */
    const Basis& get_inverse_world_inertia_tensor() const { return inverse_world_inertia_tensor; }

    /** @brief Gets the inertia tensor in world coordinates
     *  @return Reference to the world space inertia tensor matrix */
    const Basis& get_world_inertia_tensor() const { return world_inertia_tensor; }
    

    /** @brief Enables or disables gravity for this rigid body
     *  @param p_enabled True to enable gravity, false to disable */
    void set_gravity_enabled(bool p_enabled);

    /** @brief Checks if gravity is enabled for this rigid body
     *  @return True if gravity is enabled, false otherwise */
    bool is_gravity_enabled() const;

    /** @brief Flag controlling whether forces should be integrated
     *  When true, accumulated forces will be integrated during physics updates */
    bool integrate_forces_enabled;

    /** @brief Enables or disables force integration for this rigid body
     *  @param p_enabled True to enable force integration, false to disable */
    void set_integrate_forces_enabled(bool p_enabled);

    /** @brief Checks if force integration is enabled for this rigid body
     *  @return True if force integration is enabled, false otherwise */
    bool is_integrate_forces_enabled() const;


};

} // namespace godot

#endif // RIGID_BODY_CUSTOM_H
