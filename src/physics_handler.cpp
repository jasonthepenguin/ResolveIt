// Implementation file "physics_handler.cpp"


#include "physics_handler.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>




using namespace godot;





void PhysicsHandler::_bind_methods() {
    ClassDB::bind_method(D_METHOD("gather_bodies"), &PhysicsHandler::gather_bodies);
    ClassDB::bind_method(D_METHOD("integrate_all_body_forces", "delta"), &PhysicsHandler::integrate_all_body_forces);
    ClassDB::bind_method(D_METHOD("update_server_transforms"), &PhysicsHandler::update_server_transforms);
    
    
}

PhysicsHandler::PhysicsHandler() {
    physics_server = PhysicsServer3D::get_singleton();
}

PhysicsHandler::~PhysicsHandler() {
    // Cleanup if necessary
}

void PhysicsHandler::_ready() {

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

    // build manifolds for collision pairs
    std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash> manifold_map;
    find_manifolds(manifold_map); // builds our manifolds ( so all our collding bodies are paired)

    
    // impulse iteration solving 
    int impulse_iteration = 5;
    // Process all manifolds eg perhaps loop this like 5 times
    for(int i = 0; i < impulse_iteration; ++i){

        for (auto& pair : manifold_map) {
            Manifold& manifold = pair.second;
            resolve_collision(manifold, delta); // calc impulse and accumulate velocity
        }

    }

   // integrate all body forces ( integrate velocity, position, orientation etc )
   integrate_all_body_forces(delta);
   update_server_transforms();

   // positional correction
   apply_positional_corrections(manifold_map);
   update_server_transforms();


}

void PhysicsHandler::gather_bodies() {
    for (int i = 0; i < get_child_count(); ++i) {
        Node *child = get_child(i);
        if (RigidBodyCustom *rigid_body = Object::cast_to<RigidBodyCustom>(child)) {
            UtilityFunctions::print("gathered a body!");
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

void PhysicsHandler::find_manifolds(std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& manifold_map)
{

    for (auto *rigid_body : rigid_bodies) {
        PhysicsDirectBodyState3D* state = physics_server->body_get_direct_state(rigid_body->get_body_rid());
        if (state) {
            int contact_count = state->get_contact_count();
            for (int i = 0; i < contact_count; ++i) {
                Vector3 collision_normal = state->get_contact_local_normal(i).normalized();
                RID other_rid = state->get_contact_collider(i);

                Vector3 collision_point = state->get_contact_local_position(i); // position of contact on body in global coords

                Object* obj = ObjectDB::get_instance(state->get_contact_collider_id(i));
                Node* other_node = Object::cast_to<Node>(obj);
                bool other_is_static = false;
                
                
                RigidBodyCustom* other_body = nullptr;


                if (rid_map.find(other_rid) != rid_map.end()) {
                    other_body = rid_map[other_rid];
                } else if (other_node && other_node->is_class("StaticBody3D")){
                    other_is_static = true;
                    //UtilityFunctions::print("Hit a static body!");
                }

                // Create a key for the manifold
                ManifoldKey key{rigid_body, other_body};



               // Vector3 penetration_vector = local_contact_point - collision_point;
                Vector3 penetration_vector = state->get_contact_local_position(i) - state->get_contact_collider_position(i);
                float penetration_depth = penetration_vector.dot(collision_normal);
                // print penetration depth
               // UtilityFunctions::print("---");
              //  UtilityFunctions::print("penetration depth");
               // UtilityFunctions::print(penetration_depth);
              // UtilityFunctions::print("---");



                // Check if manifold exists
                auto it = manifold_map.find(key);
                if (it == manifold_map.end()) {
                    // Manifold doesn't exist, create a new one
                    Manifold manifold;
                    manifold.body_a = rigid_body;
                    manifold.body_b_node = other_node;
                    manifold.body_b_is_static = other_is_static;
                    manifold.contact_points.push_back(collision_point);
                    manifold.collision_normals.push_back(collision_normal);
                    manifold.penetrations.push_back(penetration_depth);
                    manifold_map[key] = manifold;
                } else {
                    // Add contact to existing manifold
                    Manifold& manifold = it->second;
                    manifold.contact_points.push_back(collision_point);
                    manifold.collision_normals.push_back(collision_normal);
                    manifold.penetrations.push_back(penetration_depth);
                }
            }
        }
    }    

}


void PhysicsHandler::resolve_collision(Manifold& manifold, double delta) {
    RigidBodyCustom* body_a = manifold.body_a;
    RigidBodyCustom* body_b = nullptr;

    Vector3 body_b_velocity = Vector3();
    float body_b_inv_mass = 0.0f;
    float body_b_restitution = 1.0f;

    if(!manifold.body_b_is_static) {
        body_b = Object::cast_to<RigidBodyCustom>(manifold.body_b_node);
        if (body_b) {
            body_b_velocity = body_b->get_velocity();
            body_b_inv_mass = body_b->get_inv_mass();
            body_b_restitution = body_b->get_restitution();
        }
    }

    // Process each contact point independently
    //UtilityFunctions::print("---");
    for (size_t i = 0; i < manifold.contact_points.size(); ++i) {
        Vector3 collision_normal = manifold.collision_normals[i];
        
        // Compute relative velocity
        Vector3 relative_velocity = body_a->get_velocity() - body_b_velocity;
        float velocity_along_normal = relative_velocity.dot(collision_normal);

        // Skip if objects are separating
        if (velocity_along_normal > 0) {
            continue;
        }

        // Calculate restitution
        float restitution = MIN(body_a->get_restitution(), body_b_restitution);

        // Compute impulse scalar
        float j = -(1.0f + restitution) * velocity_along_normal;
        float mass_term = body_a->get_inv_mass() + body_b_inv_mass;
        if (mass_term == 0.0f) {
            continue;
        }
        
        j /= mass_term;

        // Apply impulse
        Vector3 impulse = collision_normal * j;
        
        // Debug output
        /*
        UtilityFunctions::print("---");
        UtilityFunctions::print("Collision Normal: ", collision_normal);
        UtilityFunctions::print("Relative Velocity: ", relative_velocity);
        UtilityFunctions::print("Impulse Magnitude: ", j);
        UtilityFunctions::print("Body A Velocity Before: ", body_a->get_velocity());
        UtilityFunctions::print("---");
        */
        body_a->set_velocity(body_a->get_velocity() + impulse * body_a->get_inv_mass());
        if (body_b && !manifold.body_b_is_static) {
            body_b->set_velocity(body_b->get_velocity() - impulse * body_b_inv_mass);
        }

        //UtilityFunctions::print("Body A Velocity After: ", body_a->get_velocity());
        //UtilityFunctions::print("-------------------");
    }
    //UtilityFunctions::print("---");
}

void PhysicsHandler::apply_positional_corrections(std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& manifold_map) {
 

    for (const auto& pair : manifold_map) {
        const Manifold& manifold = pair.second;
        RigidBodyCustom* body_a = manifold.body_a;
        RigidBodyCustom* body_b = nullptr;
        float body_b_mass = INFINITY;

        if (!manifold.body_b_is_static) {
            body_b = Object::cast_to<RigidBodyCustom>(manifold.body_b_node);
            if (body_b) {
                body_b_mass = body_b->get_mass();
            }
        }
        
        for (size_t i = 0; i < manifold.contact_points.size(); ++i) {
            float penetration = manifold.penetrations[i];
            //UtilityFunctions::print(penetration);
            if (std::abs(penetration) > POSITION_SLOP ) {
                Vector3 correction = manifold.collision_normals[i] * (penetration - POSITION_SLOP) * CORRECTION_PERCENT;

                if (body_b_mass == INFINITY)
                {
                    // then only move body a
                    body_a->set_position(body_a->get_position() - correction);
                }
                else{
                    float total_mass = body_a->get_mass() + body_b_mass;
                    float ratio_a = body_b_mass / total_mass;
                    float ratio_b = body_a->get_mass() / total_mass;

                    body_a->set_position(body_a->get_position() - correction * ratio_a);
                    body_b->set_position(body_b->get_position() + correction * ratio_b);

                }
                // Static bodies are not moved
            }
        }
    }
}





void PhysicsHandler::update_server_transforms() {
    for (auto *rigid_body : rigid_bodies) {
        rigid_body->update_server_transforms();
    }
}