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
    ClassDB::bind_method(D_METHOD("update_server_transforms"), &RigidBodyCustom::update_server_transforms);
    
    // Physics simulation methods
    ClassDB::bind_method(D_METHOD("integrate_forces", "delta_time"), &RigidBodyCustom::integrate_forces);
    ClassDB::bind_method(D_METHOD("apply_force", "force"), &RigidBodyCustom::apply_force);
    ClassDB::bind_method(D_METHOD("apply_impulse"), &RigidBodyCustom::apply_impulse);
    ClassDB::bind_method(D_METHOD("apply_torque", "p_torque"), &RigidBodyCustom::apply_torque);
    ClassDB::bind_method(D_METHOD("apply_impulse_off_centre", "impulse", "rel_pos"), &RigidBodyCustom::apply_impulse_off_centre);
    
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
    ClassDB::bind_method(D_METHOD("update_inertia_tensor"), &RigidBodyCustom::update_inertia_tensor);
    
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
        PhysicsHandler::singleton->deregister_rigidbody(this);
    }
}


godot::RigidBodyCustom::RigidBodyCustom()
    : physics_server(nullptr),
      body_rid(),
      mesh_rid(),
      collision_shape(nullptr),
      mesh_instance(nullptr),
      //body_trans(),
      velocity(Vector3(0, 0, 0)),
      previous_basis(Basis()),
      angular_velocity(Vector3()),
      torque(Vector3()),
      old_velocity(Vector3(0, 0, 0)),
      forces(Vector3(0, 0, 0)),
      mass(1.0f),
      inverse_mass(1.0f),
      restitution(0.80f),
      gravity(Vector3(0, -9.8, 0)),
      old_position(),
      center_of_mass_local(Vector3(0,0,0)),
      center_of_mass_global(Vector3(0,0,0)),
      gravity_enabled(true),
      integrate_forces_enabled(true),  // Initialize the new member
      collision_layer(1),
      collision_mask(1) // default to layer / mask 1
      
       {
    // Constructor


    if (PhysicsHandler::singleton) {
        PhysicsHandler::singleton->register_rigidbody(this);
    }

    //inertia_tensor = Basis().scaled(Vector3(1,1,1));
    //inverse_inertia_tensor = inertia_tensor.inverse();
}

godot::RigidBodyCustom::~RigidBodyCustom() {
    // Destructor
}


void godot::RigidBodyCustom::set_gravity(const Vector3& p_gravity) {
    gravity = p_gravity;
}


void godot::RigidBodyCustom::set_center_of_mass_local(const Vector3& p_center_of_mass) {
    center_of_mass_local = p_center_of_mass;
    // Update global center of mass
    center_of_mass_global = get_global_transform().xform(center_of_mass_local);
}

Vector3 godot::RigidBodyCustom::get_center_of_mass_local() const {
    return center_of_mass_local;
}

Vector3 godot::RigidBodyCustom::get_center_of_mass_global() const {
    return center_of_mass_global;
}


void godot::RigidBodyCustom::set_gravity_enabled(bool p_enabled) {
    gravity_enabled = p_enabled;
}

bool godot::RigidBodyCustom::is_gravity_enabled() const {
    return gravity_enabled;
}

void godot::RigidBodyCustom::_process(double delta) {
    // Process logic
}

void godot::RigidBodyCustom::_ready() {
    // Initialize Transform as user may change it in the editor
    body_trans = get_global_transform();
    position = body_trans.origin;
    old_position = position;

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
           // UtilityFunctions::print("Found a collision shape.");
        } else if (child->is_class("MeshInstance3D")) {
            mesh_instance = Object::cast_to<MeshInstance3D>(child);
           // UtilityFunctions::print("Found a mesh instance.");
        }
    }

    if (collision_shape != nullptr) {
        // Set up the body in the physics server
        body_rid = physics_server->body_create();

        
        physics_server->body_attach_object_instance_id(body_rid, get_instance_id());

        physics_server->body_set_max_contacts_reported(body_rid, 5);
        //physics_server->body_set_collision_layer(body_rid, 1);
        //physics_server->body_set_collision_mask(body_rid, 1);
        physics_server->body_set_collision_layer(body_rid, collision_layer);
        physics_server->body_set_collision_mask(body_rid, collision_mask);
        physics_server->body_set_space(body_rid, get_world_3d()->get_space());
        physics_server->body_add_shape(body_rid, collision_shape->get_shape()->get_rid());
        physics_server->body_set_state(body_rid, PhysicsServer3D::BODY_STATE_TRANSFORM, body_trans);
        physics_server->body_set_shape_transform(body_rid, 0, Transform3D());
        physics_server->body_set_omit_force_integration(body_rid, true);
        physics_server->body_set_mode(body_rid, PhysicsServer3D::BODY_MODE_RIGID);

        //UtilityFunctions::print("Added collision shape to body in the physics server.");
        

        // Update global center of mass based on where ever the user has placed RigidBodyCustom in their scene
        center_of_mass_global = get_global_transform().xform(center_of_mass_local);
        // calculate our inertia tensor based on collision shape
        update_inertia_tensor();
        update_world_inertia_tensor();
        

    }

    //UtilityFunctions::print("Initialization complete.");


    // Test impulse application
    //apply_torque(Vector3(10,0,0));
    //apply_impulse_off_centre(Vector3(60, 0, 0), Vector3(0, 1, 0));  // Force applied away from center
}

void godot::RigidBodyCustom::update_inertia_tensor()
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

    inertia_tensor = Basis().scaled(inertia);
    
    inverse_inertia_tensor = inertia_tensor.inverse();


     // For debugging ( print calculated inertia values to be certain )
     
    //UtilityFunctions::print("Calculated inertia tensor for shape: ", shape_class);
    //UtilityFunctions::print("Inertia values: ", inertia);

    
    //UtilityFunctions::print("Inertia tensor values : ");
    //UtilityFunctions::print(inertia_tensor);
    

    // Debug prints
    //UtilityFunctions::print("Box size: ", size);
    //UtilityFunctions::print("Mass: ", mass);
    
    
    //UtilityFunctions::print("the shape class is : ");
    //UtilityFunctions::print(collision_shape->get_shape()->get_class());
    

    // determine shape to use correct primitive shape inertia alogirthm calc

}

void godot::RigidBodyCustom::set_trans(const Transform3D &new_trans) {
    body_trans = new_trans;
    position = body_trans.origin; // geometric position

    // Update the global center of mass based on the new transform
    center_of_mass_global = body_trans.xform(center_of_mass_local);

    if(body_trans.basis != previous_basis){
        update_world_inertia_tensor();
        previous_basis = body_trans.basis;
        //UtilityFunctions::print("rotation, so world inertia tensor is updated.");
    }
    

    set_global_transform(body_trans);
}

Transform3D godot::RigidBodyCustom::get_trans() const {
    return body_trans;
}


RID godot::RigidBodyCustom::get_body_rid() const {
    return body_rid;
}

void godot::RigidBodyCustom::update_server_transforms() {
    // Update physics server with new transform
    // update with the geometric centre

    if(!physics_server || !body_rid.is_valid())
    {
        UtilityFunctions::print("Issue with physics server or validity of custom rigid body RID");
        return;
    }

    physics_server->body_set_state(body_rid, PhysicsServer3D::BODY_STATE_TRANSFORM, get_trans());
}

// set pos
void godot::RigidBodyCustom::set_position(const Vector3 &new_position) {
    //position = new_position;
    body_trans.origin = new_position;
    set_trans(body_trans);
    
}


// get gravity
Vector3 godot::RigidBodyCustom::get_gravity() const {
    return gravity;
}


void godot::RigidBodyCustom::apply_impulse(const Vector3& impulse){
    // attempting method different from cookbook as that seemed to just add velocity directly
    // this way at least we are taking the mass of the object into account

    // LINEAR VELOCITY
    velocity = velocity + (impulse * inverse_mass); // scale the impulse based on objects mass
    
    // TODO : ANGULAR VERSION OF THIS FUNCTION SO WE CAN APPLY IMPULSE OFF CENTRE ( eg rotational velocity  + linear velocity)
    // point of application and angular component later etc

}

//  (Improved Euler/Heun's Method) decided to implement this when reading chapter Chapter 7, real time simulations (better methods section)
void godot::RigidBodyCustom::integrate_forces(double delta_time) {
    // Add check at the start of the method
    if (!integrate_forces_enabled) {
        // Clear forces and torque even when disabled
        forces = Vector3();
        torque = Vector3();
        return;
    }

    // Store old state
    old_position = position;
    old_velocity = velocity;

    //update_world_inertia_tensor();



    //Vector3 acceleration = (forces) * inverse_mass + gravity;
    
    Vector3 acceleration = forces * inverse_mass;
    Vector3 angular_acceleration = inverse_world_inertia_tensor.xform(torque);

    // Energy thresholds for coming to rest
    const float min_linear_kinetic_energy = 0.01f;  // 0.5 * m * v^2
    const float min_angular_kinetic_energy = 0.01f; // 0.5 * I * ω^2
    

    // Update velocities
    velocity += acceleration * delta_time;
    angular_velocity += angular_acceleration * delta_time;

    // Calculate kinetic energies
    float linear_kinetic_energy = 0.5f * mass * velocity.length_squared();
    float angular_kinetic_energy = 0.5f * angular_velocity.dot(inertia_tensor.xform(angular_velocity));

    
    // Bring to rest if energy is below thresholds
    
    if (Math::abs(linear_kinetic_energy) < min_linear_kinetic_energy) {
        velocity = Vector3();
    }

    if (Math::abs(angular_kinetic_energy) < min_angular_kinetic_energy) {
        angular_velocity = Vector3();
    }
    

    // Update positions using new velocities
    //position += velocity * delta_time;
    center_of_mass_global += velocity * delta_time;

     // Update the body's geometric position based on center of mass movement
    Transform3D new_trans = body_trans;
    new_trans.origin = center_of_mass_global - body_trans.basis.xform(center_of_mass_local); // geometric position i think

    // Update orientation using new angular velocity
    Vector3 rotation_amount = angular_velocity * delta_time;
    float angle = rotation_amount.length();
    if (angle > 0.0f) {
        Vector3 rotation_axis = rotation_amount.normalized();
        Basis rotation = Basis(rotation_axis, angle);
        new_trans.basis = rotation * body_trans.basis;
        new_trans.basis = new_trans.basis.orthonormalized(); // adjusts basis so axes are both orthogonal and normalized
        // to maintain proper rotation matrix without skewing effects
        update_world_inertia_tensor();

    }

   

    // Update transform
    set_trans(new_trans);

    // Debug output if needed
    /*
    UtilityFunctions::print("\n=== Physics Update ===");
    UtilityFunctions::print("Position: ", position);
    UtilityFunctions::print("Velocity: ", velocity);
    UtilityFunctions::print("Acceleration: ", acceleration);
    UtilityFunctions::print("Angular Velocity: ", angular_velocity);
    UtilityFunctions::print("Linear KE: ", linear_kinetic_energy);
    UtilityFunctions::print("Angular KE: ", angular_kinetic_energy);
    UtilityFunctions::print("Forces: ", forces);
    UtilityFunctions::print("Torque: ", torque);
    */

    // Clear forces and torque for next frame
    forces = Vector3();
    torque = Vector3();
}




void godot::RigidBodyCustom::set_velocity(const Vector3 &new_velocity) {
    velocity = new_velocity;
}

Vector3 godot::RigidBodyCustom::get_velocity() const {
    return velocity;
}

void godot::RigidBodyCustom::apply_force(const Vector3 &force) {
    forces += force;
}

void godot::RigidBodyCustom::set_restitution(float new_restitution) {
    restitution = new_restitution;
}

float godot::RigidBodyCustom::get_restitution() const {
    return restitution;
}

// get and set mass
void godot::RigidBodyCustom::set_mass(float new_mass) {
    mass = new_mass;
    if(mass != 0.0f){
        inverse_mass = 1.0f / mass;
    }

    update_inertia_tensor();
    update_world_inertia_tensor();
}

float godot::RigidBodyCustom::get_mass() const {
    return mass;
}

float godot::RigidBodyCustom::get_inv_mass() const {
   if(mass == 0.0f)
   {
        return 0.0f;
   }
   return inverse_mass;
}

// get position
Vector3 godot::RigidBodyCustom::get_old_position() const {
    return old_position;
}

Vector3 godot::RigidBodyCustom::get_position() const {
    return position;
}



void godot::RigidBodyCustom::set_angular_velocity(const Vector3& p_angular_velocity) {
    angular_velocity = p_angular_velocity;
}

Vector3 godot::RigidBodyCustom::get_angular_velocity() const {
    return angular_velocity;
}

void godot::RigidBodyCustom::apply_torque(const Vector3& p_torque) {
    torque += p_torque;
}

void godot::RigidBodyCustom::apply_impulse_off_centre(const Vector3& impulse, const Vector3& rel_pos) {
    // Apply linear impulse
    velocity += impulse * inverse_mass;

    // Apply angular impulse
    Vector3 angular_impulse = rel_pos.cross(impulse);
    //angular_velocity += inverse_inertia_tensor.xform(angular_impulse); 
    angular_velocity += inverse_world_inertia_tensor.xform(angular_impulse); 
    // .xform method seems to just be the transform method, in this case its allowing us matrix-vector multiplication


    
   // UtilityFunctions::print("Applied impulse: ", impulse);
   // UtilityFunctions::print("At relative position: ", rel_pos);
   // UtilityFunctions::print("Resulting angular impulse: ", rel_pos.cross(impulse));
    
    
}

void godot::RigidBodyCustom::update_world_inertia_tensor()
{
    Transform3D current_transform = get_trans();
    // get rotation basis
    Basis rotation = current_transform.basis;
    inverse_world_inertia_tensor = rotation * inverse_inertia_tensor * rotation.transposed();
}

void godot::RigidBodyCustom::set_integrate_forces_enabled(bool p_enabled) {
    integrate_forces_enabled = p_enabled;
}

bool godot::RigidBodyCustom::is_integrate_forces_enabled() const {
    return integrate_forces_enabled;
}


void godot::RigidBodyCustom::set_collision_layer_value(int p_layer_number, bool p_value) {
    ERR_FAIL_COND_MSG(p_layer_number < 1 || p_layer_number > 32, "Layer number must be between 1 and 32.");

    if (p_value) {
        collision_layer |= (1 << (p_layer_number - 1));
    } else {
        collision_layer &= ~(1 << (p_layer_number - 1));
    }
    if (body_rid.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_layer(body_rid, collision_layer);
    }
}

bool godot::RigidBodyCustom::get_collision_layer_value(int p_layer_number) const {
    return collision_layer & (1 << (p_layer_number - 1));
}

void godot::RigidBodyCustom::set_collision_mask_value(int p_layer_number, bool p_value) {
    ERR_FAIL_COND_MSG(p_layer_number < 1 || p_layer_number > 32, "Layer number must be between 1 and 32.");
    
    if (p_value) {
        collision_mask |= (1 << (p_layer_number - 1));
    } else {
        collision_mask &= ~(1 << (p_layer_number - 1));
    }
    if (body_rid.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_mask(body_rid, collision_mask);
    }
}

bool godot::RigidBodyCustom::get_collision_mask_value(int p_layer_number) const {
    return collision_mask & (1 << (p_layer_number - 1));
}

void godot::RigidBodyCustom::set_collision_layer(uint32_t p_layer) {
    collision_layer = p_layer;
    if (body_rid.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_layer(body_rid, collision_layer);
    }
}

uint32_t godot::RigidBodyCustom::get_collision_layer() const {
    return collision_layer;
}

void godot::RigidBodyCustom::set_collision_mask(uint32_t p_mask) {
    collision_mask = p_mask;
    if (body_rid.is_valid()) {
        PhysicsServer3D::get_singleton()->body_set_collision_mask(body_rid, collision_mask);
    }
}

uint32_t RigidBodyCustom::get_collision_mask() const {
    return collision_mask;
}
