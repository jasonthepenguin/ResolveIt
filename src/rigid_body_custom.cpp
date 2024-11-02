#include "rigid_body_custom.h"
#include "physics_handler.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;


void godot::RigidBodyCustom::_bind_methods()
{
    // Method bindings for transforms and basic properties
    ClassDB::bind_method(D_METHOD("set_trans", "new_trans"), &RigidBodyCustom::set_trans);
    ClassDB::bind_method(D_METHOD("get_trans"), &RigidBodyCustom::get_trans);
    ClassDB::bind_method(D_METHOD("get_body_rid"), &RigidBodyCustom::get_body_rid);
    ClassDB::bind_method(D_METHOD("update_server_transforms"), &RigidBodyCustom::UpdateServerTransforms);
    
    // Physics simulation methods
    ClassDB::bind_method(D_METHOD("integrate_forces", "delta_time"), &RigidBodyCustom::IntegrateForces);
    ClassDB::bind_method(D_METHOD("apply_force", "force"), &RigidBodyCustom::ApplyForce);
    ClassDB::bind_method(D_METHOD("apply_impulse"), &RigidBodyCustom::ApplyImpulse);
    ClassDB::bind_method(D_METHOD("apply_torque", "p_torque"), &RigidBodyCustom::ApplyTorque);
    ClassDB::bind_method(D_METHOD("apply_impulse_off_centre", "impulse", "rel_pos"), &RigidBodyCustom::ApplyImpulseOffCentre);
    
    // Basic property getters and setters
    ClassDB::bind_method(D_METHOD("set_restitution", "new_restitution"), &RigidBodyCustom::set_restitution);
    ClassDB::bind_method(D_METHOD("get_restitution"), &RigidBodyCustom::get_restitution);
    ClassDB::bind_method(D_METHOD("set_mass", "new_mass"), &RigidBodyCustom::set_mass);
    ClassDB::bind_method(D_METHOD("get_mass"), &RigidBodyCustom::get_mass);
    ClassDB::bind_method(D_METHOD("get_inv_mass"), &RigidBodyCustom::get_inv_mass);
    
    // Position and velocity methods
    ClassDB::bind_method(D_METHOD("get_old_position"), &RigidBodyCustom::get_old_position);
    ClassDB::bind_method(D_METHOD("get_position"), &RigidBodyCustom::get_position);
    ClassDB::bind_method(D_METHOD("set_velocity", "velocity"), &RigidBodyCustom::set_velocity);
    ClassDB::bind_method(D_METHOD("get_velocity"), &RigidBodyCustom::get_velocity);
    
    // Angular motion methods
    ClassDB::bind_method(D_METHOD("set_angular_velocity", "angular_velocity"), &RigidBodyCustom::set_angular_velocity);
    ClassDB::bind_method(D_METHOD("get_angular_velocity"), &RigidBodyCustom::get_angular_velocity);
    
    // Gravity methods
    ClassDB::bind_method(D_METHOD("set_gravity", "gravity"), &RigidBodyCustom::set_gravity);
    ClassDB::bind_method(D_METHOD("get_gravity"), &RigidBodyCustom::get_gravity);
    ClassDB::bind_method(D_METHOD("set_gravity_enabled", "enabled"), &RigidBodyCustom::set_gravity_enabled);
    ClassDB::bind_method(D_METHOD("is_gravity_enabled"), &RigidBodyCustom::is_gravity_enabled);
    
    // Center of mass methods
    ClassDB::bind_method(D_METHOD("set_center_of_mass_local", "center_of_mass"), &RigidBodyCustom::set_center_of_mass_local);
    ClassDB::bind_method(D_METHOD("get_center_of_mass_local"), &RigidBodyCustom::get_center_of_mass_local);
    ClassDB::bind_method(D_METHOD("get_center_of_mass_global"), &RigidBodyCustom::get_center_of_mass_global);
    
    // Inertia tensor methods
    ClassDB::bind_method(D_METHOD("get_inverse_inertia_tensor"), &RigidBodyCustom::get_inverse_inertia_tensor);
    ClassDB::bind_method(D_METHOD("update_inertia_tensor"), &RigidBodyCustom::UpdateInertiaTensor);
    ClassDB::bind_method(D_METHOD("get_world_inertia_tensor"), &RigidBodyCustom::get_world_inertia_tensor);
    
    // Integration control methods
    ClassDB::bind_method(D_METHOD("set_integrate_forces_enabled", "enabled"), &RigidBodyCustom::set_integrate_forces_enabled);
    ClassDB::bind_method(D_METHOD("is_integrate_forces_enabled"), &RigidBodyCustom::is_integrate_forces_enabled);
    
    // Collision layer/mask methods
    ClassDB::bind_method(D_METHOD("set_collision_layer", "layer"), &RigidBodyCustom::set_collision_layer);
    ClassDB::bind_method(D_METHOD("get_collision_layer"), &RigidBodyCustom::get_collision_layer);
    ClassDB::bind_method(D_METHOD("set_collision_mask", "mask"), &RigidBodyCustom::set_collision_mask);
    ClassDB::bind_method(D_METHOD("get_collision_mask"), &RigidBodyCustom::get_collision_mask);
    ClassDB::bind_method(D_METHOD("set_collision_layer_value", "layer_number", "value"), &RigidBodyCustom::set_collision_layer_value);
    ClassDB::bind_method(D_METHOD("get_collision_layer_value", "layer_number"), &RigidBodyCustom::get_collision_layer_value);
    ClassDB::bind_method(D_METHOD("set_collision_mask_value", "layer_number", "value"), &RigidBodyCustom::set_collision_mask_value);
    ClassDB::bind_method(D_METHOD("get_collision_mask_value", "layer_number"), &RigidBodyCustom::get_collision_mask_value);

    // Property bindings for editor UI
    ADD_GROUP("Physics Properties", "");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::FLOAT, "mass"), "set_mass", "get_mass");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::FLOAT, "restitution"), "set_restitution", "get_restitution");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::VECTOR3, "gravity"), "set_gravity", "get_gravity");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::BOOL, "gravity_enabled"), "set_gravity_enabled", "is_gravity_enabled");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::BOOL, "integrate_forces_enabled"), "set_integrate_forces_enabled", "is_integrate_forces_enabled");
    
    ADD_GROUP("Motion", "");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::VECTOR3, "velocity"), "set_velocity", "get_velocity");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::VECTOR3, "angular_velocity"), "set_angular_velocity", "get_angular_velocity");
    ClassDB::add_property("RigidBodyCustom", PropertyInfo(Variant::VECTOR3, "center_of_mass_local"), "set_center_of_mass_local", "get_center_of_mass_local");
    
    ADD_GROUP("Collision", "");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "collision_layer", PROPERTY_HINT_LAYERS_3D_PHYSICS), "set_collision_layer", "get_collision_layer");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "collision_mask", PROPERTY_HINT_LAYERS_3D_PHYSICS), "set_collision_mask", "get_collision_mask");
}


void godot::RigidBodyCustom::_exit_tree() {
    // Deregister this rigid body from the PhysicsHandler
    if (PhysicsHandler::singleton) {
        PhysicsHandler::singleton->DeregisterRigidbody(this);
    }
}


godot::RigidBodyCustom::RigidBodyCustom()
    : physics_server_(nullptr),
      body_rid_(),
      mesh_rid_(),
      collision_shape_(nullptr),
      mesh_instance_(nullptr),
      velocity_(Vector3(0, 0, 0)),
      previous_basis_(Basis()),
      angular_velocity_(Vector3()),
      torque_(Vector3()),
      old_velocity_(Vector3(0, 0, 0)),
      forces_(Vector3(0, 0, 0)),
      mass_(1.0f),
      inverse_mass_(1.0f),
      restitution_(1.0f),
      gravity_(Vector3(0, -9.8, 0)),
      position_(),
      old_position_(),
      center_of_mass_local_(Vector3(0,0,0)),
      center_of_mass_global_(Vector3(0,0,0)),
      gravity_enabled_(true),
      integrate_forces_enabled_(true),
      collision_layer_(1),
      collision_mask_(1)
      
       {
    // Constructor


    if (PhysicsHandler::singleton) {
        PhysicsHandler::singleton->RegisterRigidbody(this);
    }

    //inertia_tensor = Basis().scaled(Vector3(1,1,1));
    //inverse_inertia_tensor = inertia_tensor.inverse();
}

godot::RigidBodyCustom::~RigidBodyCustom() {
    // Destructor

    // Free the physics body if it exists
    if (physics_server_ && body_rid_.is_valid()) {
        physics_server_->free_rid(body_rid_);
    }

    // dont need to clear collision shape and mesh instace here as godots scene tree clears it for us
}


void godot::RigidBodyCustom::set_gravity(const Vector3& p_gravity) {
    gravity_ = p_gravity;
}


void godot::RigidBodyCustom::set_center_of_mass_local(const Vector3& p_center_of_mass) {
    center_of_mass_local_ = p_center_of_mass;
    // Update global center of mass
    center_of_mass_global_ = get_global_transform().xform(center_of_mass_local_);
}

Vector3 godot::RigidBodyCustom::get_center_of_mass_local() const {
    return center_of_mass_local_;
}

Vector3 godot::RigidBodyCustom::get_center_of_mass_global() const {
    return center_of_mass_global_;
}


void godot::RigidBodyCustom::set_gravity_enabled(bool p_enabled) {
    gravity_enabled_ = p_enabled;
}

bool godot::RigidBodyCustom::is_gravity_enabled() const {
    return gravity_enabled_;
}

void godot::RigidBodyCustom::_process(double delta) {
    // Process logic
}

void godot::RigidBodyCustom::_ready() {
    // Initialize Transform as user may change it in the editor
    body_trans_ = get_global_transform();
    position_ = body_trans_.origin;
    old_position_ = position_;
    previous_basis_ = body_trans_.basis;

    // Get the physics server
    physics_server_ = PhysicsServer3D::get_singleton();

    // Find required child nodes
    for (int i = 0; i < get_child_count(); i++) {
        Node *child = get_child(i);

        if (child->is_class("CollisionShape3D")) {
            collision_shape_ = Object::cast_to<CollisionShape3D>(child);
           
        } else if (child->is_class("MeshInstance3D")) {
            mesh_instance_ = Object::cast_to<MeshInstance3D>(child);
           
        }
    }

    if (collision_shape_ != nullptr) {
        // Set up the body in the physics server
        body_rid_ = physics_server_->body_create();

        
        physics_server_->body_attach_object_instance_id(body_rid_, get_instance_id());

        physics_server_->body_set_max_contacts_reported(body_rid_, 5);
        //physics_server_->body_set_collision_layer(body_rid_, 1);
        //physics_server_->body_set_collision_mask(body_rid_, 1);
        physics_server_->body_set_collision_layer(body_rid_, collision_layer_);
        physics_server_->body_set_collision_mask(body_rid_, collision_mask_);
        physics_server_->body_set_space(body_rid_, get_world_3d()->get_space());
        physics_server_->body_add_shape(body_rid_, collision_shape_->get_shape()->get_rid());
        physics_server_->body_set_state(body_rid_, PhysicsServer3D::BODY_STATE_TRANSFORM, body_trans_);
        physics_server_->body_set_shape_transform(body_rid_, 0, Transform3D());
        physics_server_->body_set_omit_force_integration(body_rid_, true);
        physics_server_->body_set_mode(body_rid_, PhysicsServer3D::BODY_MODE_RIGID);

        
        

        // Update global center of mass based on where ever the user has placed RigidBodyCustom in their scene
        center_of_mass_global_ = get_global_transform().xform(center_of_mass_local_);
        // calculate our inertia tensor based on collision shape
        UpdateInertiaTensor();
        UpdateWorldInertiaTensor();
        

    }

}

void godot::RigidBodyCustom::UpdateInertiaTensor()
{
    if(collision_shape_ == nullptr) return;

    // get shapes
    // so far just work with the primitives SphereShape3D and BoxShape3D

    Vector3 inertia;
    String shape_class = collision_shape_->get_shape()->get_class();

    Vector3 size;

    if(shape_class == "SphereShape3D"){
        Ref<SphereShape3D> sphere = Object::cast_to<SphereShape3D>(collision_shape_->get_shape().ptr());
        float radius = sphere->get_radius();
        // Inertia calculation for a sphere I = 2/5 * m * r^2 for solid sphere
        float i = (2.0f/5.0f) * mass_ * radius * radius;
        inertia = Vector3(i,i,i);
    }
    else if(shape_class == "BoxShape3D"){
        Ref<BoxShape3D> box = collision_shape_->get_shape();
        size = box->get_size();  // full size

        // For a box: I = (1/12) * mass * (width² + height²)
        inertia.x = (1.0f/12.0f) * mass_ * (size.y * size.y + size.z * size.z);
        inertia.y = (1.0f/12.0f) * mass_ * (size.x * size.x + size.z * size.z);
        inertia.z = (1.0f/12.0f) * mass_ * (size.x * size.x + size.y * size.y);
    }
    // other shapes when get the chance and inertia. 

    inertia_tensor_ = Basis().scaled(inertia);
    
    inverse_inertia_tensor_ = inertia_tensor_.inverse();


}

void godot::RigidBodyCustom::set_trans(const Transform3D &new_trans) {
    body_trans_ = new_trans;
    position_ = body_trans_.origin; // geometric position

    // Update the global center of mass based on the new transform
    center_of_mass_global_ = body_trans_.xform(center_of_mass_local_);

    if(body_trans_.basis != previous_basis_){
        UpdateWorldInertiaTensor();
        previous_basis_ = body_trans_.basis;
        //UtilityFunctions::print("rotation, so world inertia tensor is updated.");
    }
    

    set_global_transform(body_trans_);
}

Transform3D godot::RigidBodyCustom::get_trans() const {
    return body_trans_;
}


RID godot::RigidBodyCustom::get_body_rid() const {
    return body_rid_;
}

void godot::RigidBodyCustom::UpdateServerTransforms() {
    // Update physics server with new transform
    // update with the geometric centre

    if(!physics_server_ || !body_rid_.is_valid())
    {
        UtilityFunctions::print("Issue with physics server or validity of custom rigid body RID");
        return;
    }

    physics_server_->body_set_state(body_rid_, PhysicsServer3D::BODY_STATE_TRANSFORM, get_trans());
}

// set pos
void godot::RigidBodyCustom::set_position(const Vector3 &new_position) {
    //position = new_position;
    body_trans_.origin = new_position;
    set_trans(body_trans_);
    
}


// get gravity
Vector3 godot::RigidBodyCustom::get_gravity() const {
    return gravity_;
}


void godot::RigidBodyCustom::ApplyImpulse(const Vector3& impulse){
   
    // LINEAR VELOCITY
    velocity_ = velocity_ + (impulse * inverse_mass_); // scale the impulse based on objects mass
    

}

//  (Explicit Euler integration) decided to implement this when reading chapter Chapter 7, real time simulations (better methods section)
void godot::RigidBodyCustom::IntegrateForces(double delta_time) {
    // Add check at the start of the method
    if (!integrate_forces_enabled_) {
        // Clear forces and torque even when disabled
        forces_ = Vector3();
        torque_ = Vector3();
        return;
    }

    // Store old state
    old_position_ = position_;
    old_velocity_ = velocity_;

    

    //Vector3 acceleration = (forces_) * inverse_mass_ + gravity_;
    
    Vector3 acceleration = forces_ * inverse_mass_;
    Vector3 angular_acceleration = inverse_world_inertia_tensor_.xform(torque_);

    // Energy thresholds for coming to rest
    const float min_linear_kinetic_energy = 0.01f;  // 0.5 * m * v^2
    const float min_angular_kinetic_energy = 0.01f; // 0.5 * I * ω^2
    

    // Update velocities
    velocity_ += acceleration * delta_time;
    angular_velocity_ += angular_acceleration * delta_time;

    // Calculate kinetic energies
    float linear_kinetic_energy = 0.5f * mass_ * velocity_.length_squared();
    float angular_kinetic_energy = 0.5f * angular_velocity_.dot(inertia_tensor_.xform(angular_velocity_));

    
    // Bring to rest if energy is below thresholds
    
    if (Math::abs(linear_kinetic_energy) < min_linear_kinetic_energy) {
        velocity_ = Vector3();
    }

    if (Math::abs(angular_kinetic_energy) < min_angular_kinetic_energy) {
        angular_velocity_ = Vector3();
    }
    

    // Update positions using new velocities
    //position_ += velocity_ * delta_time;
    center_of_mass_global_ += velocity_ * delta_time;

     // Update the body's geometric position based on center of mass movement
    Transform3D new_trans = body_trans_;
    new_trans.origin = center_of_mass_global_ - body_trans_.basis.xform(center_of_mass_local_); // geometric position i think

    // Update orientation using new angular velocity
    Vector3 rotation_amount = angular_velocity_ * delta_time;
    float angle = rotation_amount.length();
    if (angle > 0.0f) {
        Vector3 rotation_axis = rotation_amount.normalized();
        Basis rotation = Basis(rotation_axis, angle);
        new_trans.basis = rotation * body_trans_.basis;
        new_trans.basis = new_trans.basis.orthonormalized(); // adjusts basis so axes are both orthogonal and normalized
        // to maintain proper rotation matrix without skewing effects
        UpdateWorldInertiaTensor();

    }

   

    // Update transform
    set_trans(new_trans);



    // Clear forces and torque for next frame
    forces_ = Vector3();
    torque_ = Vector3();
}




void godot::RigidBodyCustom::set_velocity(const Vector3 &new_velocity) {
    velocity_ = new_velocity;
}

Vector3 godot::RigidBodyCustom::get_velocity() const {
    return velocity_;
}

void godot::RigidBodyCustom::ApplyForce(const Vector3 &force) {
    forces_ += force;
}

void godot::RigidBodyCustom::set_restitution(float new_restitution) {
    restitution_ = new_restitution;
}

float godot::RigidBodyCustom::get_restitution() const {
    return restitution_;
}

// get and set mass
void godot::RigidBodyCustom::set_mass(float new_mass) {
    mass_ = new_mass;
    if(mass_ != 0.0f){
        inverse_mass_ = 1.0f / mass_;
    }

    UpdateInertiaTensor();
    UpdateWorldInertiaTensor();
}

float godot::RigidBodyCustom::get_mass() const {
    return mass_;
}

float godot::RigidBodyCustom::get_inv_mass() const {
   if(mass_ == 0.0f)
   {
        return 0.0f;
   }
   return inverse_mass_;
}

// get position
Vector3 godot::RigidBodyCustom::get_old_position() const {
    return old_position_;
}

Vector3 godot::RigidBodyCustom::get_position() const {
    return position_;
}



void godot::RigidBodyCustom::set_angular_velocity(const Vector3& p_angular_velocity) {
    angular_velocity_ = p_angular_velocity;
}

Vector3 godot::RigidBodyCustom::get_angular_velocity() const {
    return angular_velocity_;
}

void godot::RigidBodyCustom::ApplyTorque(const Vector3& p_torque) {
    torque_ += p_torque;
}

void godot::RigidBodyCustom::ApplyImpulseOffCentre(const Vector3& impulse, const Vector3& rel_pos) {
    // Apply linear impulse
    velocity_ += impulse * inverse_mass_;

    // Apply angular impulse
    Vector3 angular_impulse = rel_pos.cross(impulse);
    //angular_velocity_ += inverse_inertia_tensor_.xform(angular_impulse); 
    angular_velocity_ += inverse_world_inertia_tensor_.xform(angular_impulse); 
    // .xform method seems to just be the transform method, in this case its allowing us matrix-vector multiplication


    
    
}

void godot::RigidBodyCustom::UpdateWorldInertiaTensor()
{
    Transform3D current_transform = get_trans();
    Basis rotation = current_transform.basis;
    
    // Get Euler angles in degrees
    //Vector3 euler_angles = rotation.get_euler(EULER_ORDER_XYZ);
    //Vector3 degrees = euler_angles * (180.0f / Math_PI);  // Convert radians to degrees
    
    
    world_inertia_tensor_ = rotation * inertia_tensor_ * rotation.transposed(); // for testing purposes have both

    inverse_world_inertia_tensor_ = rotation * inverse_inertia_tensor_ * rotation.transposed();

}

void godot::RigidBodyCustom::set_integrate_forces_enabled(bool p_enabled) {
    integrate_forces_enabled_ = p_enabled;
}

bool godot::RigidBodyCustom::is_integrate_forces_enabled() const {
    return integrate_forces_enabled_;
}


void godot::RigidBodyCustom::set_collision_layer_value(int p_layer_number, bool p_value) {
    ERR_FAIL_COND_MSG(p_layer_number < 1 || p_layer_number > 32, "Layer number must be between 1 and 32.");

    if (p_value) {
        collision_layer_ |= (1 << (p_layer_number - 1));
    } else {
        collision_layer_ &= ~(1 << (p_layer_number - 1));
    }
    if (body_rid_.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_layer(body_rid_, collision_layer_);
    }
}

bool godot::RigidBodyCustom::get_collision_layer_value(int p_layer_number) const {
    return collision_layer_ & (1 << (p_layer_number - 1));
}

void godot::RigidBodyCustom::set_collision_mask_value(int p_layer_number, bool p_value) {
    ERR_FAIL_COND_MSG(p_layer_number < 1 || p_layer_number > 32, "Layer number must be between 1 and 32.");
    
    if (p_value) {
        collision_mask_ |= (1 << (p_layer_number - 1));
    } else {
        collision_mask_ &= ~(1 << (p_layer_number - 1));
    }
    if (body_rid_.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_mask(body_rid_, collision_mask_);
    }
}

bool godot::RigidBodyCustom::get_collision_mask_value(int p_layer_number) const {
    return collision_mask_ & (1 << (p_layer_number - 1));
}

void godot::RigidBodyCustom::set_collision_layer(uint32_t p_layer) {
    collision_layer_ = p_layer;
    if (body_rid_.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_layer(body_rid_, collision_layer_);
    }
}

uint32_t godot::RigidBodyCustom::get_collision_layer() const {
    return collision_layer_;
}

void godot::RigidBodyCustom::set_collision_mask(uint32_t p_mask) {
    collision_mask_ = p_mask;
    if (body_rid_.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_mask(body_rid_, collision_mask_);
    }
}

uint32_t RigidBodyCustom::get_collision_mask() const {
    return collision_mask_;
}

