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
            //UtilityFunctions::print(penetration);
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


// Copy the resolve_collision and apply_positional_corrections methods from PhysicsHandler
void CollisionResolver::resolve_collision(Manifold& manifold, double delta) {
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

       
        if(std::abs(denominator) < epsilon){
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