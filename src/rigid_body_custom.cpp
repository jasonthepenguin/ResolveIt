#include "rigid_body_custom.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void RigidBodyCustom::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_trans", "new_trans"), &RigidBodyCustom::set_trans);
    ClassDB::bind_method(D_METHOD("get_trans"), &RigidBodyCustom::get_trans);
    ClassDB::bind_method(D_METHOD("get_body_rid"), &RigidBodyCustom::get_body_rid);
    ClassDB::bind_method(D_METHOD("update_server_transforms"), &RigidBodyCustom::update_server_transforms);
    ClassDB::bind_method(D_METHOD("integrate_forces", "delta_time"), &RigidBodyCustom::integrate_forces);
    ClassDB::bind_method(D_METHOD("set_velocity", "new_velocity"), &RigidBodyCustom::set_velocity);
    ClassDB::bind_method(D_METHOD("get_velocity"), &RigidBodyCustom::get_velocity);
    ClassDB::bind_method(D_METHOD("apply_force", "force"), &RigidBodyCustom::apply_force);
    ClassDB::bind_method(D_METHOD("set_restitution", "new_restitution"), &RigidBodyCustom::set_restitution);
    ClassDB::bind_method(D_METHOD("get_restitution"), &RigidBodyCustom::get_restitution);
    ClassDB::bind_method(D_METHOD("set_mass", "new_mass"), &RigidBodyCustom::set_mass);
    ClassDB::bind_method(D_METHOD("get_mass"), &RigidBodyCustom::get_mass);
    ClassDB::bind_method(D_METHOD("get_inv_mass"), &RigidBodyCustom::get_inv_mass);
    ClassDB::bind_method(D_METHOD("get_old_position"), &RigidBodyCustom::get_old_position);
    ClassDB::bind_method(D_METHOD("get_position"), &RigidBodyCustom::get_position);
    ClassDB::bind_method(D_METHOD("get_gravity"), &RigidBodyCustom::get_gravity);
    ClassDB::bind_method(D_METHOD("apply_impulse"), &RigidBodyCustom::apply_impulse);

    ClassDB::bind_method(D_METHOD("set_angular_velocity", "angular_velocity"), &RigidBodyCustom::set_angular_velocity);
    ClassDB::bind_method(D_METHOD("get_angular_velocity"), &RigidBodyCustom::get_angular_velocity);
    ClassDB::bind_method(D_METHOD("apply_torque", "p_torque"), &RigidBodyCustom::apply_torque);
    ClassDB::bind_method(D_METHOD("apply_impulse_off_centre", "impulse", "rel_pos"), &RigidBodyCustom::apply_impulse_off_centre);

    // Add to _bind_methods():
    ClassDB::bind_method(D_METHOD("get_inverse_inertia_tensor"), &RigidBodyCustom::get_inverse_inertia_tensor);
    //void update_inertia_tensor();

    ClassDB::bind_method(D_METHOD("update_inertia_tensor"), &RigidBodyCustom::update_inertia_tensor);


    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::VECTOR3, "velocity"), "set_velocity", "get_velocity");
}



RigidBodyCustom::RigidBodyCustom()
    : physics_server(nullptr),
      body_rid(),
      mesh_rid(),
      collision_shape(nullptr),
      mesh_instance(nullptr),
      body_trans(),
      velocity(Vector3(0, 0, 0)),
      angular_velocity(Vector3()),
      torque(Vector3()),
      old_velocity(Vector3(0, 0, 0)),
      forces(Vector3(0, 0, 0)),
      mass(1.0f),
      inverse_mass(1.0f),
      restitution(0.95f),
      friction(1.0f),
      gravity(Vector3(0, -9.8, 0)),
      position(),
      old_position() {
    // Constructor

    inertia_tensor = Basis().scaled(Vector3(1,1,1));
    inverse_inertia_tensor = inertia_tensor.inverse();
}

RigidBodyCustom::~RigidBodyCustom() {
    // Destructor
}

void RigidBodyCustom::_process(double delta) {
    // Process logic
}

void RigidBodyCustom::_ready() {
    // Initialize Transform as user may change it in the editor
    body_trans = get_global_transform();
    position = body_trans.origin;

    // print position
    //UtilityFunctions::print("Position: ");
    //UtilityFunctions::print(body_trans.origin);

    // Get the physics server
    physics_server = PhysicsServer3D::get_singleton();

    // Find required child nodes
    for (int i = 0; i < get_child_count(); i++) {
        Node *child = get_child(i);

        if (child->is_class("CollisionShape3D")) {
            collision_shape = Object::cast_to<CollisionShape3D>(child);
            UtilityFunctions::print("Found a collision shape.");
        } else if (child->is_class("MeshInstance3D")) {
            mesh_instance = Object::cast_to<MeshInstance3D>(child);
            UtilityFunctions::print("Found a mesh instance.");
        }
    }

    if (collision_shape != nullptr) {
        // Set up the body in the physics server
        body_rid = physics_server->body_create();
        physics_server->body_set_max_contacts_reported(body_rid, 5);
        physics_server->body_set_collision_layer(body_rid, 1);
        physics_server->body_set_collision_mask(body_rid, 1);
        physics_server->body_set_space(body_rid, get_world_3d()->get_space());
        physics_server->body_add_shape(body_rid, collision_shape->get_shape()->get_rid());
        physics_server->body_set_state(body_rid, PhysicsServer3D::BODY_STATE_TRANSFORM, body_trans);
        physics_server->body_set_shape_transform(body_rid, 0, Transform3D());
        physics_server->body_set_omit_force_integration(body_rid, true);
        physics_server->body_set_mode(body_rid, PhysicsServer3D::BODY_MODE_RIGID);

        UtilityFunctions::print("Added collision shape to body in the physics server.");

        // calculate our inertia tensor based on collision shape
        update_inertia_tensor();

        

    }

    UtilityFunctions::print("Initialization complete.");


       // Test impulse application
    UtilityFunctions::print("\n=== Test Impulse Setup ===");
    Vector3 impulse(10.0, 0.0, 0.0);
    Vector3 rel_pos(0.0, 1.0, 0.0);
    
    UtilityFunctions::print("Impulse Vector: ", impulse);
    UtilityFunctions::print("Application Point: ", rel_pos);
    UtilityFunctions::print("Initial velocity: ", get_velocity());
    UtilityFunctions::print("Initial angular velocity: ", get_angular_velocity());
    
    //apply_impulse_off_centre(impulse, rel_pos);
    
    UtilityFunctions::print("\n=== After Impulse Application ===");
    UtilityFunctions::print("New linear velocity: ", get_velocity());
    UtilityFunctions::print("New angular velocity: ", get_angular_velocity());
    UtilityFunctions::print("Expected rotation axis: Z (should rotate backwards)");


    //apply_torque(Vector3(10,0,0));
    //apply_impulse_off_centre(Vector3(60, 0, 0), Vector3(0, 1, 0));  // Force applied away from center
}

void RigidBodyCustom::update_inertia_tensor()
{
    if(collision_shape == nullptr) return;

    // get shapes
    // so far just work with the primitives we assume are being used eg SphereShape3D etc

    Vector3 inertia;
    String shape_class = collision_shape->get_shape()->get_class();

    Vector3 size;

    if(shape_class == "SphereShape3D"){
        //UtilityFunctions::print("we have a SphereShape3D");
        Ref<SphereShape3D> sphere = Object::cast_to<SphereShape3D>(collision_shape->get_shape().ptr());
        float radius = sphere->get_radius();
        //UtilityFunctions::print("our radius from calling ref of sphere : ");
        //UtilityFunctions::print(sphere->get_radius());
        // Inertia calculation for a sphere I = 2/5 * m * r^2 for solid sphere
        float i = (2.0f/5.0f) * mass * radius * radius;
        inertia = Vector3(i,i,i);
    }
    else if(shape_class == "BoxShape3D"){
        Ref<BoxShape3D> box = collision_shape->get_shape();
        size = box->get_size();  // full size

        // For a box: I = (1/12) * mass * (width² + height²)
        inertia.x = (1.0f/12.0f) * mass * (size.y * size.y + size.z * size.z);
        inertia.y = (1.0f/12.0f) * mass * (size.x * size.x + size.z * size.z);
        inertia.z = (1.0f/12.0f) * mass * (size.x * size.x + size.y * size.y);
    }
    // other shapes when get the chance and inertia. 


     // For debugging ( print calculated inertia values to be certain )
    UtilityFunctions::print("Calculated inertia tensor for shape: ", shape_class);
    UtilityFunctions::print("Inertia values: ", inertia);

    inertia_tensor = Basis().scaled(inertia);
    UtilityFunctions::print("Inertia tensor values : ");
    UtilityFunctions::print(inertia_tensor);
    inverse_inertia_tensor = inertia_tensor.inverse();

    // Debug prints
    UtilityFunctions::print("Box size: ", size);
    UtilityFunctions::print("Mass: ", mass);
    

    //UtilityFunctions::print("the shape class is : ");
    //UtilityFunctions::print(collision_shape->get_shape()->get_class());
    

    // determine shape to use correct primitive shape inertia alogirthm calc

}

void RigidBodyCustom::set_trans(const Transform3D &new_trans) {
    body_trans = new_trans;
    position = body_trans.origin;
    set_global_transform(body_trans);
}

Transform3D RigidBodyCustom::get_trans() const {
    return body_trans;
}


RID RigidBodyCustom::get_body_rid() const {
    return body_rid;
}

void RigidBodyCustom::update_server_transforms() {
    // Update physics server with new transform
    physics_server->body_set_state(body_rid, PhysicsServer3D::BODY_STATE_TRANSFORM, get_trans());
    //set_global_transform(get_trans());
}

// set pos
void RigidBodyCustom::set_position(const Vector3 &new_position) {
    //position = new_position;
    body_trans.origin = new_position;
    set_trans(body_trans);
    
}


// get gravity
Vector3 RigidBodyCustom::get_gravity() const {
    return gravity;
}


void RigidBodyCustom::apply_impulse(const Vector3& impulse){
    // attempting method different from cookbook as that seemed to just add velocity directly
    // this way at least we are taking the mass of the object into account

    // LINEAR VELOCITY
    velocity = velocity + (impulse * inverse_mass); // scale the impulse based on objects mass

    // TODO : ANGULAR VERSION OF THIS FUNCTION SO WE CAN APPLY IMPULSE OFF CENTRE ( eg rotational velocity  + linear velocity)
    // point of application and angular component later etc

}

//  (Improved Euler/Heun's Method) decided to implement this when reading chapter Chapter 7, real time simulations (better methods section)
void RigidBodyCustom::integrate_forces(double delta_time) {
    // Store old state
    old_position = position;
    old_velocity = velocity;

    // Step 1: Calculate initial derivatives (k1)
    Vector3 acceleration1 = (forces * inverse_mass) + gravity;
    Vector3 angular_acceleration1 = inverse_inertia_tensor.xform(torque);
    
    Vector3 k1_vel = acceleration1 * delta_time;
    Vector3 k1_pos = velocity * delta_time;
    Vector3 k1_angular = angular_acceleration1 * delta_time;
    
    // Step 2: Calculate predicted state
    Vector3 predicted_pos = position + k1_pos;
    Vector3 predicted_vel = velocity + k1_vel;
    Vector3 predicted_angular_vel = angular_velocity + k1_angular;
    
    // Step 3: Calculate derivatives at predicted state (k2)
    // Note: In this case acceleration is constant, but in general it might depend
    // on position/velocity
    Vector3 acceleration2 = (forces * inverse_mass) + gravity;
    Vector3 angular_acceleration2 = inverse_inertia_tensor.xform(torque);
    
    Vector3 k2_vel = acceleration2 * delta_time;
    Vector3 k2_pos = predicted_vel * delta_time;
    Vector3 k2_angular = angular_acceleration2 * delta_time;
    
    // Step 4: Final update using average of k1 and k2
    velocity += (k1_vel + k2_vel) * 0.5f;
    position += (k1_pos + k2_pos) * 0.5f;
    angular_velocity += (k1_angular + k2_angular) * 0.5f;

    // Update orientation using final angular velocity
    Vector3 rotation_amount = angular_velocity * delta_time;
    float angle = rotation_amount.length();
    if (angle > 0.0f) {
        Vector3 rotation_axis = rotation_amount.normalized();
        Basis rotation = Basis(rotation_axis, angle);
        body_trans.basis = rotation * body_trans.basis;
        body_trans.basis = body_trans.basis.orthogonalized();
    }

    // Update transform
    body_trans.origin = position;
    set_trans(body_trans);

       // Print debug information
    /*
    UtilityFunctions::print("\n=== Physics Update ===");
    UtilityFunctions::print("Position: ", position);
    UtilityFunctions::print("Velocity: ", velocity);
    UtilityFunctions::print("Acceleration: ", acceleration);
    UtilityFunctions::print("Angular Velocity: ", angular_velocity);
    UtilityFunctions::print("Forces: ", forces);
    UtilityFunctions::print("Torque: ", torque);
    */

    // Clear forces and torque for next frame
    forces = Vector3();
    torque = Vector3();
}




void RigidBodyCustom::set_velocity(const Vector3 &new_velocity) {
    velocity = new_velocity;
}

Vector3 RigidBodyCustom::get_velocity() const {
    return velocity;
}

void RigidBodyCustom::apply_force(const Vector3 &force) {
    forces += force;
}

void RigidBodyCustom::set_restitution(float new_restitution) {
    restitution = new_restitution;
}

float RigidBodyCustom::get_restitution() const {
    return restitution;
}

// get and set mass
void RigidBodyCustom::set_mass(float new_mass) {
    mass = new_mass;
    if(mass != 0.0f){
        inverse_mass = 1.0f / mass;
    }
}

float RigidBodyCustom::get_mass() const {
    return mass;
}

float RigidBodyCustom::get_inv_mass() const {
   if(mass == 0.0f)
   {
        return 0.0f;
   }
   return inverse_mass;
}

// get position
Vector3 RigidBodyCustom::get_old_position() const {
    return old_position;
}

Vector3 RigidBodyCustom::get_position() const {
    return position;
}



void RigidBodyCustom::set_angular_velocity(const Vector3& p_angular_velocity) {
    angular_velocity = p_angular_velocity;
}

Vector3 RigidBodyCustom::get_angular_velocity() const {
    return angular_velocity;
}

void RigidBodyCustom::apply_torque(const Vector3& p_torque) {
    torque += p_torque;
}

void RigidBodyCustom::apply_impulse_off_centre(const Vector3& impulse, const Vector3& rel_pos) {
    // Apply linear impulse
    velocity += impulse * inverse_mass;

    // Apply angular impulse
    Vector3 angular_impulse = rel_pos.cross(impulse);
    angular_velocity += inverse_inertia_tensor.xform(angular_impulse); 
    // .xform method seems to just be the transform method, in this case its allowing us matrix-vector multiplication


    UtilityFunctions::print("Applied impulse: ", impulse);
    UtilityFunctions::print("At relative position: ", rel_pos);
    UtilityFunctions::print("Resulting angular impulse: ", rel_pos.cross(impulse));
    
    
}
