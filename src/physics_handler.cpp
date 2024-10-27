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
    
    

}


PhysicsHandler::PhysicsHandler() {
    physics_server = PhysicsServer3D::get_singleton();
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

    // Apply gravity force ( to be accumulated then integrated appropriately in rigidbody integrate forces )
    for(auto &rigid_body : rigid_bodies)
    {
        if(rigid_body->is_gravity_enabled())
        {
            Vector3 gravity_force = rigid_body->get_gravity() * rigid_body->get_mass();
            rigid_body->apply_force(gravity_force); // accumulate the force from gravity
        }
    }

    // build manifolds for collision pairs
    std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash> manifold_map;
    find_manifolds(manifold_map); // builds our manifolds ( so all our collding bodies are paired)

    
    // impulse iteration solving 
    int impulse_iteration = 1; //= 5;
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
                
                
                
                RigidBodyCustom* other_body = nullptr;
                bool other_is_static = true;

                auto it = rid_map.find(other_rid);

               // UtilityFunctions::print("=== Manifold Creation Debug ===");
                //UtilityFunctions::print("Found RID in map: ", (it != rid_map.end()));
                if (other_node) {
                    //UtilityFunctions::print("Other node class: ", other_node->get_class());
                }

                if (it != rid_map.end()) {
                    other_body = rid_map[other_rid];
                    other_is_static = false;  // Explicitly set to false for dynamic bodies
                    //UtilityFunctions::print("Found dynamic body in rid_map");
                } else if (other_node && other_node->is_class("StaticBody3D")) {
                    other_is_static = true;
                    other_body = nullptr;
                   // UtilityFunctions::print("Found static body");
                } else {
                    //UtilityFunctions::print("Warning: Unhandled collision case");
                    other_is_static = true;  // Default to static for safety
                    other_body = nullptr;
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
                auto manifold_it = manifold_map.find(key);
                if (manifold_it == manifold_map.end()) {
                    // Manifold doesn't exist, create a new one
                    Manifold manifold;
                    manifold.body_a = rigid_body;
                    manifold.body_b = other_body;
                    manifold.body_b_is_static = other_is_static;
                    manifold.contact_points.push_back(collision_point);
                    manifold.collision_normals.push_back(collision_normal);
                    manifold.penetrations.push_back(penetration_depth);
                    manifold_map[key] = manifold;
                } else {
                    // Add contact to existing manifold
                    Manifold& manifold = manifold_it->second;
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
   // RigidBodyCustom* body_b = nullptr;
    RigidBodyCustom* body_b = manifold.body_b;

    Vector3 body_b_velocity = Vector3();
    Vector3 body_b_angular_velocity = Vector3();
    float body_b_inv_mass = 0.0f;
    float body_b_restitution = 1.0f;

   // UtilityFunctions::print("Is body B static");
   // UtilityFunctions::print(manifold.body_b_is_static);


    if (!manifold.body_b_is_static && body_b){
        body_b_velocity = body_b->get_velocity();
        body_b_angular_velocity = body_b->get_angular_velocity();
        body_b_inv_mass = body_b->get_inv_mass();
        body_b_restitution = body_b->get_restitution();
    }

    // Process each contact point independently
    for (size_t i = 0; i < manifold.contact_points.size(); ++i) {
        Vector3 collision_normal = manifold.collision_normals[i];
        Vector3 contact_point = manifold.contact_points[i];

        // Calculate relative contact points
        //Vector3 ra = contact_point - body_a->get_position();
        //Vector3 rb = manifold.body_b_is_static ? Vector3() : contact_point - body_b->get_position();

        Vector3 ra = contact_point - body_a->get_center_of_mass_global();
        Vector3 rb = manifold.body_b_is_static ? Vector3() : contact_point - body_b->get_center_of_mass_global();

        // Compute velocities at contact points
        Vector3 vel_a = body_a->get_velocity() + body_a->get_angular_velocity().cross(ra);
        Vector3 vel_b = manifold.body_b_is_static ? Vector3() : body_b->get_velocity() + body_b->get_angular_velocity().cross(rb);

        // Compute relative velocity at contact point
        Vector3 relative_velocity = vel_a - vel_b;

        float velocity_along_normal = relative_velocity.dot(collision_normal);

        // Skip if objects are separating
        if (velocity_along_normal > 0) {
            continue;
        }
        /*
          // Log pre-collision state
        UtilityFunctions::print("\n=== Collision Event ===");
        UtilityFunctions::print("Body A Properties:");
        UtilityFunctions::print("- Mass: ", body_a->get_mass());
        UtilityFunctions::print("- Inertia Tensor: ", body_a->get_inverse_world_inertia_tensor().inverse());
        UtilityFunctions::print("- Center of Mass: ", body_a->get_center_of_mass_global());
        UtilityFunctions::print("- Pre-collision Linear Velocity: ", body_a->get_velocity());
        UtilityFunctions::print("- Pre-collision Angular Velocity: ", body_a->get_angular_velocity());

        if (!manifold.body_b_is_static && body_b) {
            UtilityFunctions::print("\nBody B Properties:");
            UtilityFunctions::print("- Mass: ", body_b->get_mass());
            UtilityFunctions::print("- Inertia Tensor: ", body_b->get_inverse_world_inertia_tensor().inverse());
            UtilityFunctions::print("- Center of Mass: ", body_b->get_center_of_mass_global());
            UtilityFunctions::print("- Pre-collision Linear Velocity: ", body_b->get_velocity());
            UtilityFunctions::print("- Pre-collision Angular Velocity: ", body_b->get_angular_velocity());
        } else {
            UtilityFunctions::print("\nBody B: Static/None");
        }

        UtilityFunctions::print("\nCollision Properties:");
        UtilityFunctions::print("- Contact Normal: ", collision_normal);
        UtilityFunctions::print("- Contact Point: ", contact_point);
        UtilityFunctions::print("- r1 (Body A arm): ", ra);
        UtilityFunctions::print("- r2 (Body B arm): ", rb);
        UtilityFunctions::print("- Coefficient of Restitution: ", MIN(body_a->get_restitution(), body_b_restitution));
        */
       
        // Calculate restitution (coefficient of restitution)
        float restitution = MIN(body_a->get_restitution(), body_b_restitution);

        // Calculate angular contribution terms
        Vector3 raxn = ra.cross(collision_normal);

        //Vector3 angular_term_a = body_a->get_inverse_inertia_tensor().xform(raxn).cross(ra);
        
        // replacing to now use the world inverse inertia tensor
        Vector3 angular_term_a = body_a->get_inverse_world_inertia_tensor().xform(raxn).cross(ra);

        Vector3 angular_term_b = Vector3();
        if (!manifold.body_b_is_static) {
            Vector3 rbxn = rb.cross(collision_normal);
            //angular_term_b = body_b->get_inverse_inertia_tensor().xform(rbxn).cross(rb);
            // changing to now use the inverse world inertia tensor
            angular_term_b = body_b->get_inverse_world_inertia_tensor().xform(rbxn).cross(rb);
        }

        // Compute impulse scalar
        float j = -(1.0f + restitution) * velocity_along_normal;
        float denominator = body_a->get_inv_mass() + body_b_inv_mass + collision_normal.dot(angular_term_a + angular_term_b);

        const float EPSILON = 0.0001f;
        if(std::abs(denominator) < EPSILON){
            continue;
        }
        if (denominator == 0.0f) {
            continue;
        }

        j /= denominator;

        // Apply impulse
        Vector3 impulse = collision_normal * j;

        // Apply Linear and Angular impulse to body A
        body_a->apply_impulse_off_centre(impulse, ra);

        /*
        UtilityFunctions::print("---");
        UtilityFunctions::print("Impulse Scalar j: ", j);
        UtilityFunctions::print("Impulse: ", impulse);
        UtilityFunctions::print("ra: ", ra);
        UtilityFunctions::print("rb: ", rb);
        UtilityFunctions::print("Updated Linear Velocity A: ", body_a->get_velocity());
        UtilityFunctions::print("Updated Angular Velocity A: ", body_a->get_angular_velocity());
        */

        // Apply impulse to body B if it's not static and not null
        //if (!manifold.body_b_is_static && body_b) {
        if (!manifold.body_b_is_static && body_b) {
            body_b->apply_impulse_off_centre(-impulse, rb);

            //UtilityFunctions::print("Updated Linear Velocity B: ", body_b->get_velocity());
            //UtilityFunctions::print("Updated Angular Velocity B: ", body_b->get_angular_velocity());
        }

        /*
         // After computing impulse
        UtilityFunctions::print("\nImpulse Details:");
        UtilityFunctions::print("- Impulse Magnitude (λ): ", j);
        UtilityFunctions::print("- Impulse Vector: ", impulse);

            // Log post-collision state
        UtilityFunctions::print("\nPost-collision State:");
        UtilityFunctions::print("Body A:");
        UtilityFunctions::print("- Linear Velocity: ", body_a->get_velocity());
        UtilityFunctions::print("- Angular Velocity: ", body_a->get_angular_velocity());

        if (!manifold.body_b_is_static && body_b) {
            UtilityFunctions::print("Body B:");
            UtilityFunctions::print("- Linear Velocity: ", body_b->get_velocity());
            UtilityFunctions::print("- Angular Velocity: ", body_b->get_angular_velocity());
        }
        UtilityFunctions::print("===========================\n");
        */


    }
}



void PhysicsHandler::apply_positional_corrections(std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& manifold_map) {
 

    for (const auto& pair : manifold_map) {
        const Manifold& manifold = pair.second;
        RigidBodyCustom* body_a = manifold.body_a;
        RigidBodyCustom* body_b = nullptr;
        float body_b_mass = INFINITY;

        if (!manifold.body_b_is_static) {
            //body_b = Object::cast_to<RigidBodyCustom>(manifold.body_b);
            body_b = manifold.body_b;
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



