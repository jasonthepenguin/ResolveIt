#include "collision_resolver.h"
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

CollisionResolver::CollisionResolver() {}

void CollisionResolver::set_parameters(float p_correction_percent, float p_position_slop, float p_epsilon) {
    correction_percent = p_correction_percent;
    position_slop = p_position_slop;
    epsilon = p_epsilon;
}

void CollisionResolver::resolve_collisions(double delta, int impulse_iterations) {
    if (!collision_detector) return;
    
    auto& manifold_map = collision_detector->get_manifold_map();
    for(int i = 0; i < impulse_iterations; ++i) {
        for (auto& pair : manifold_map) {
            // Use reference to modify the original manifold
            Manifold& manifold = pair.second;
            resolve_collision(manifold, delta);
        }
    }
}

void CollisionResolver::apply_positional_corrections() {
    
    if(!collision_detector) return;

    auto& manifold_map = collision_detector->get_manifold_map();
    
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
            ////UtilityFunctions::print(penetration);
            if (std::abs(penetration) > position_slop ) {
                Vector3 correction = manifold.collision_normals[i] * (penetration - position_slop) * correction_percent;

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



void CollisionResolver::resolve_collision(Manifold& manifold, double delta) {
    RigidBodyCustom* body_a = manifold.body_a;
    RigidBodyCustom* body_b = manifold.body_b;

    Vector3 body_b_velocity = Vector3();
    Vector3 body_b_angular_velocity = Vector3();
    float body_b_inv_mass = 0.0f;
    float body_b_restitution = 1.0f;

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

        // Calculate restitution (coefficient of restitution)
        float restitution = MIN(body_a->get_restitution(), body_b_restitution);

        // log BEFORE state
        //log_collision_state("Pre", manifold, contact_point, collision_normal, restitution, delta);

        // (Proceed with impulse calculation)

        // Calculate angular contribution terms
        Vector3 raxn = ra.cross(collision_normal);
        Vector3 angular_term_a = body_a->get_inverse_world_inertia_tensor().xform(raxn).cross(ra);

        Vector3 angular_term_b = Vector3();
        if (!manifold.body_b_is_static) {
            Vector3 rbxn = rb.cross(collision_normal);
            angular_term_b = body_b->get_inverse_world_inertia_tensor().xform(rbxn).cross(rb);
        }

        // Compute impulse scalar
        float j = -(1.0f + restitution) * velocity_along_normal;
        float denominator = body_a->get_inv_mass() + body_b_inv_mass + collision_normal.dot(angular_term_a + angular_term_b);

        if (std::abs(denominator) < epsilon){
            continue;
        }
        if (denominator == 0.0f) {
            continue;
        }

        j /= denominator;



        // Apply impulse
        Vector3 impulse = collision_normal * j;

         // Print impulse value
        //UtilityFunctions::print("Applied impulse magnitude: ", impulse.length());
        //UtilityFunctions::print("Applied impulse vector: ", impulse);


        // Apply Linear and Angular impulse to body A
        body_a->apply_impulse_off_centre(impulse, ra);

        // Apply impulse to body B if it's not static and not null
        if (!manifold.body_b_is_static && body_b) {
            body_b->apply_impulse_off_centre(-impulse, rb);
        }

        //log_collision_state("Post", manifold, contact_point, collision_normal, restitution, delta);


    }
}

void CollisionResolver::log_collision_state(const char* phase,
                                          const Manifold& manifold,
                                          const Vector3& contact_point,
                                          const Vector3& collision_normal,
                                          float restitution,
                                          double delta) {

    
    //UtilityFunctions::print("\n=== ", phase, " Collision at Time: ", current_time, "s ===");
    
    double current_time = Time::get_singleton()->get_ticks_msec() / 1000.0; // Convert milliseconds to seconds
    UtilityFunctions::print("\n=== ", phase, " Collision at Time: ", current_time, "s ===");
    

    // Calculate system momentum and energy
    Vector3 total_linear_momentum;
    Vector3 total_angular_momentum;
    float total_kinetic_energy = 0.0f;
    
    // Body A info
    UtilityFunctions::print("Body A:");
    auto* body_a = manifold.body_a;
    UtilityFunctions::print("  - Mass: ", body_a->get_mass());
    UtilityFunctions::print("  - Position: ", body_a->get_position());
    UtilityFunctions::print("  - Center of Mass: ", body_a->get_center_of_mass_global());
    UtilityFunctions::print("  - Linear Velocity: ", body_a->get_velocity());
    UtilityFunctions::print("  - Angular Velocity: ", body_a->get_angular_velocity());
    UtilityFunctions::print("  - Local inverse Inertia: ", body_a->get_inverse_inertia_tensor());
    UtilityFunctions::print("  - World inverse Inertia: ", body_a->get_inverse_world_inertia_tensor().inverse());
    
    // Calculate body A contribution to system properties
    Vector3 linear_momentum_a = body_a->get_velocity() * body_a->get_mass();
    Vector3 angular_momentum_a = body_a->get_inverse_world_inertia_tensor().inverse().xform(
        body_a->get_angular_velocity());
    float kinetic_energy_a = 0.5f * body_a->get_mass() * body_a->get_velocity().length_squared() +
                            0.5f * body_a->get_angular_velocity().dot(angular_momentum_a);
    
    total_linear_momentum += linear_momentum_a;
    total_angular_momentum += angular_momentum_a;
    total_kinetic_energy += kinetic_energy_a;
    
    UtilityFunctions::print("  - Linear Momentum: ", linear_momentum_a);
    UtilityFunctions::print("  - Angular Momentum: ", angular_momentum_a);
    UtilityFunctions::print("  - Kinetic Energy: ", kinetic_energy_a);
    

//manifold.body_b->get_local_
    // Body B info
    UtilityFunctions::print("Body B:");
    if (manifold.body_b_is_static) {
        UtilityFunctions::print("  - Static Body");
    } else if (manifold.body_b) {
        auto* body_b = manifold.body_b;
        UtilityFunctions::print("  - Mass: ", body_b->get_mass());
        UtilityFunctions::print("  - Position: ", body_b->get_position());
        UtilityFunctions::print("  - Center of Mass: ", body_b->get_center_of_mass_global());
        UtilityFunctions::print("  - Linear Velocity: ", body_b->get_velocity());
        UtilityFunctions::print("  - Angular Velocity: ", body_b->get_angular_velocity());
        UtilityFunctions::print("  - Local inverse Inertia: ", body_b->get_inverse_inertia_tensor());
        UtilityFunctions::print("  - World inverse Inertia: ", body_b->get_inverse_world_inertia_tensor().inverse());
        
        // Calculate body B contribution to system properties
        Vector3 linear_momentum_b = body_b->get_velocity() * body_b->get_mass();
        Vector3 angular_momentum_b = body_b->get_inverse_world_inertia_tensor().inverse().xform(
            body_b->get_angular_velocity());
        float kinetic_energy_b = 0.5f * body_b->get_mass() * body_b->get_velocity().length_squared() +
                                0.5f * body_b->get_angular_velocity().dot(angular_momentum_b);
        
        total_linear_momentum += linear_momentum_b;
        total_angular_momentum += angular_momentum_b;
        total_kinetic_energy += kinetic_energy_b;
        
        UtilityFunctions::print("  - Linear Momentum: ", linear_momentum_b);
        UtilityFunctions::print("  - Angular Momentum: ", angular_momentum_b);
        UtilityFunctions::print("  - Kinetic Energy: ", kinetic_energy_b);
    }
    
    // Collision specifics
    UtilityFunctions::print("Collision Data:");
    UtilityFunctions::print("  - Contact Point: ", contact_point);
    UtilityFunctions::print("  - Normal: ", collision_normal);
    UtilityFunctions::print("  - Restitution: ", restitution);
    
    // For each contact point
    UtilityFunctions::print("Contact Points Data:");
    for (int i = 0; i < manifold.contact_points.size(); ++i) {
        UtilityFunctions::print("  Contact ", i, ":");
        UtilityFunctions::print("    - Position: ", manifold.contact_points[i]);
        UtilityFunctions::print("    - Normal: ", manifold.collision_normals[i]);
        UtilityFunctions::print("    - Penetration: ", manifold.penetrations[i]);
    }
    
    // System totals
    UtilityFunctions::print("System Totals:");
    UtilityFunctions::print("  - Total Linear Momentum: ", total_linear_momentum);
    UtilityFunctions::print("  - Total Angular Momentum: ", total_angular_momentum);
    UtilityFunctions::print("  - Total Kinetic Energy: ", total_kinetic_energy);
    
    // If this is post-collision and we stored pre-collision values, we could add:
    if (strcmp(phase, "Post") == 0) {
        // These would need to be stored as class members from pre-collision
        // UtilityFunctions::print("Conservation Checks:");
        // UtilityFunctions::print("  - Linear Momentum Change: ", 
        //     (total_linear_momentum - pre_collision_linear_momentum).length());
        // UtilityFunctions::print("  - Angular Momentum Change: ",
        //     (total_angular_momentum - pre_collision_angular_momentum).length());
        // UtilityFunctions::print("  - Energy Ratio: ", 
        //     total_kinetic_energy / pre_collision_energy);
    }
}