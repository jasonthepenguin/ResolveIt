// Implementation file "physics_handler.cpp"


#include "physics_handler.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "rigid_body_custom.h"


using namespace godot;

PhysicsHandler* PhysicsHandler::singleton = nullptr;



void PhysicsHandler::_bind_methods() {
    ClassDB::bind_method(D_METHOD("GatherBodies"), &PhysicsHandler::GatherBodies);
    ClassDB::bind_method(D_METHOD("IntegrateAllBodyForces", "delta"), &PhysicsHandler::IntegrateAllBodyForces);
    ClassDB::bind_method(D_METHOD("UpdateServerTransforms"), &PhysicsHandler::UpdateServerTransforms);
    ClassDB::bind_method(D_METHOD("get_rigid_bodies"), &PhysicsHandler::get_rigid_bodies);
    
    
    ClassDB::bind_method(D_METHOD("set_correction_percent", "value"), &PhysicsHandler::set_correction_percent);
    ClassDB::bind_method(D_METHOD("get_correction_percent"), &PhysicsHandler::get_correction_percent);
    
    ClassDB::bind_method(D_METHOD("set_position_slop", "value"), &PhysicsHandler::set_position_slop);
    ClassDB::bind_method(D_METHOD("get_position_slop"), &PhysicsHandler::get_position_slop);
    
    ClassDB::bind_method(D_METHOD("set_collision_epsilon", "value"), &PhysicsHandler::set_collision_epsilon);
    ClassDB::bind_method(D_METHOD("get_collision_epsilon"), &PhysicsHandler::get_collision_epsilon);
    
    ClassDB::bind_method(D_METHOD("set_impulse_iterations", "value"), &PhysicsHandler::set_impulse_iterations);
    ClassDB::bind_method(D_METHOD("get_impulse_iterations"), &PhysicsHandler::get_impulse_iterations);

    
    ADD_GROUP("Physics Settings", "");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "correction_percent", PROPERTY_HINT_RANGE, "0.01,1.0,0.01"), 
                "set_correction_percent", "get_correction_percent");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "position_slop", PROPERTY_HINT_RANGE, "0.001,0.1,0.001"), 
                "set_position_slop", "get_position_slop");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "collision_epsilon", PROPERTY_HINT_RANGE, "0.00001,0.001,0.00001"), 
                "set_collision_epsilon", "get_collision_epsilon");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "impulse_iterations", PROPERTY_HINT_RANGE, "1,10,1"), 
                "set_impulse_iterations", "get_impulse_iterations");
    

}


PhysicsHandler::PhysicsHandler() {
    physics_server_ = PhysicsServer3D::get_singleton();

    collision_detector_ = std::make_unique<CollisionDetector>(physics_server_);
    collision_resolver_ = std::make_unique<CollisionResolver>();

    collision_resolver_->set_collision_detector(collision_detector_.get());
}

PhysicsHandler::~PhysicsHandler() {
    rigid_bodies_.clear();
    rid_map_.clear();
    static_rid_map_.clear();

    collision_detector_.reset();
    collision_resolver_.reset();
    singleton = nullptr;
}

void PhysicsHandler::RegisterRigidbody(RigidBodyCustom* rigid_body) {
    if(!rigid_body) return;

    if (std::find(rigid_bodies_.begin(), rigid_bodies_.end(), rigid_body) == rigid_bodies_.end()) {
        rigid_bodies_.push_back(rigid_body);
        rid_map_[rigid_body->get_body_rid()] = rigid_body;
    }
}

void PhysicsHandler::DeregisterRigidbody(RigidBodyCustom* rigid_body) {
    rigid_bodies_.erase(std::remove(rigid_bodies_.begin(), rigid_bodies_.end(), rigid_body), rigid_bodies_.end());
    rid_map_.erase(rigid_body->get_body_rid());
}


Array PhysicsHandler::get_rigid_bodies() const {
    Array result;
    for (const auto* body : rigid_bodies_) {
        result.push_back(body);
    }
    return result;
}



void PhysicsHandler::_ready() {

    singleton = this;
    
    set_process_priority(1); // im testing this to see if updates to my rigid bodies are done before physics handler
    

    if(Engine::get_singleton()->is_editor_hint()){
        set_physics_process(false);
        return;
    }
    call_deferred("GatherBodies");
}

void PhysicsHandler::_physics_process(double delta) {

    // check if engine is in editor mode or not. prevent physics from running in editor mode
    if (Engine::get_singleton()->is_editor_hint()){
        return;
    }
    // begining next update, clear previous manifolds
    collision_detector_->ClearManifolds();

    // Apply gravity force ( to be accumulated then integrated appropriately in rigidbody integrate forces )
    ApplyGravityForces();


    collision_detector_->DetectCollisions(rigid_bodies_, rid_map_);

    collision_resolver_->set_parameters(correction_percent, position_slop, epsilon);
    
    // impulse iteration solving 
    collision_resolver_->ResolveCollisions(delta, impulse_iterations);


   // integrate all body forces ( integrate velocity, position, orientation etc )
    IntegrateAllBodyForces(delta);
    UpdateServerTransforms();

   // positional correction
    collision_resolver_->ApplyPositionalCorrections();
    UpdateServerTransforms();


}

void PhysicsHandler::GatherBodies() {
    for (int i = 0; i < get_child_count(); ++i) {
        Node *child = get_child(i);
        if (RigidBodyCustom *rigid_body = Object::cast_to<RigidBodyCustom>(child)) {
            
            rigid_bodies_.push_back(rigid_body);
            rid_map_[rigid_body->get_body_rid()] = rigid_body;
        }
    }
}

void PhysicsHandler::IntegrateAllBodyForces(double delta) {
    for (auto &rigid_body : rigid_bodies_) {
        rigid_body->IntegrateForces(delta);
    }
}


void PhysicsHandler::UpdateServerTransforms() {
    for (auto *rigid_body : rigid_bodies_) {
        rigid_body->UpdateServerTransforms();
    }
}



void PhysicsHandler::set_correction_percent(float p_value) {
    correction_percent = p_value;
}

float PhysicsHandler::get_correction_percent() const {
    return correction_percent;
}

void PhysicsHandler::set_position_slop(float p_value) {
    position_slop = p_value;
}

float PhysicsHandler::get_position_slop() const {
    return position_slop;
}

void PhysicsHandler::set_collision_epsilon(float p_value) {
    epsilon = p_value;
}

float PhysicsHandler::get_collision_epsilon() const {
    return epsilon;
}

void PhysicsHandler::set_impulse_iterations(int p_value) {
    impulse_iterations = p_value;
}

int PhysicsHandler::get_impulse_iterations() const {
    return impulse_iterations;
}

void PhysicsHandler::ApplyGravityForces() {
    for(auto &rigid_body : rigid_bodies_) {
        if(rigid_body->is_gravity_enabled()) {
            Vector3 gravity_force = rigid_body->get_gravity() * rigid_body->get_mass();
            rigid_body->ApplyForce(gravity_force);
        }
    }
}