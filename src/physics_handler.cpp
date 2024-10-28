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
    ClassDB::bind_method(D_METHOD("gather_bodies"), &PhysicsHandler::gather_bodies);
    ClassDB::bind_method(D_METHOD("integrate_all_body_forces", "delta"), &PhysicsHandler::integrate_all_body_forces);
    ClassDB::bind_method(D_METHOD("update_server_transforms"), &PhysicsHandler::update_server_transforms);
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
    physics_server = PhysicsServer3D::get_singleton();
    collision_detector = std::make_unique<CollisionDetector>(physics_server);
    collision_resolver = std::make_unique<CollisionResolver>();
    collision_resolver->set_collision_detector(collision_detector.get());
}

PhysicsHandler::~PhysicsHandler() {
    // Cleanup if necessary
    rigid_bodies.clear();
    rid_map.clear();
}

void PhysicsHandler::register_rigidbody(RigidBodyCustom* rigid_body) {

    if(!rigid_body) return;

    if (std::find(rigid_bodies.begin(), rigid_bodies.end(), rigid_body) == rigid_bodies.end()) {
        rigid_bodies.push_back(rigid_body);
        rid_map[rigid_body->get_body_rid()] = rigid_body;
    }
}

void PhysicsHandler::deregister_rigidbody(RigidBodyCustom* rigid_body) {
    rigid_bodies.erase(std::remove(rigid_bodies.begin(), rigid_bodies.end(), rigid_body), rigid_bodies.end());
    rid_map.erase(rigid_body->get_body_rid());
}


Array PhysicsHandler::get_rigid_bodies() const {
    Array result;
    for (const auto* body : rigid_bodies) {
        result.push_back(body);
    }
    return result;
}



void PhysicsHandler::_ready() {

    singleton = this;
    // print my current process priority
    //UtilityFunctions::print("my process priority is : ");
    set_process_priority(1); // im testing this to see if updates to my rigid bodies are done before physics handler
    //UtilityFunctions::print(get_process_priority());

    if(Engine::get_singleton()->is_editor_hint()){
        set_physics_process(false);
        return;
    }
    call_deferred("gather_bodies");
}

void PhysicsHandler::_physics_process(double delta) {

    // check if engine is in editor mode or not. prevent physics from running in editor mode
    if (Engine::get_singleton()->is_editor_hint()){
        return;
    }
    // begining next update, clear previous manifolds
    collision_detector->clear_manifolds();

    // Apply gravity force ( to be accumulated then integrated appropriately in rigidbody integrate forces )
    apply_gravity_forces();


    collision_detector->detect_collisions(rigid_bodies, rid_map);

    collision_resolver->set_parameters(correction_percent, position_slop, epsilon);
    
    // impulse iteration solving 
    collision_resolver->resolve_collisions(delta, impulse_iterations);


   // integrate all body forces ( integrate velocity, position, orientation etc )
    integrate_all_body_forces(delta);
    update_server_transforms();

   // positional correction
   //apply_positional_corrections(manifold_map);
    collision_resolver->apply_positional_corrections();
    update_server_transforms();


}

void PhysicsHandler::gather_bodies() {
    for (int i = 0; i < get_child_count(); ++i) {
        Node *child = get_child(i);
        if (RigidBodyCustom *rigid_body = Object::cast_to<RigidBodyCustom>(child)) {
            //UtilityFunctions::print("gathered a body!");
            rigid_bodies.push_back(rigid_body);
            rid_map[rigid_body->get_body_rid()] = rigid_body;
        }
    }
}

void PhysicsHandler::integrate_all_body_forces(double delta) {
    for (auto &rigid_body : rigid_bodies) {
        rigid_body->integrate_forces(delta);
    }
}


void PhysicsHandler::update_server_transforms() {
    for (auto *rigid_body : rigid_bodies) {
        rigid_body->update_server_transforms();
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

void PhysicsHandler::apply_gravity_forces() {
    for(auto &rigid_body : rigid_bodies) {
        if(rigid_body->is_gravity_enabled()) {
            Vector3 gravity_force = rigid_body->get_gravity() * rigid_body->get_mass();
            rigid_body->apply_force(gravity_force);
        }
    }
}