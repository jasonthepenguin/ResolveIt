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

        // **Add print statements here**

        // 1. Mass properties of each body (mass and inertia tensor)
        //UtilityFunctions::print("\n=== Collision Event ===");
        //UtilityFunctions::print("Body A Mass: ", body_a->get_mass());
        //UtilityFunctions::print("Body A Inertia Tensor: ", body_a->get_inverse_world_inertia_tensor().inverse());
        if (!manifold.body_b_is_static && body_b) {
            //UtilityFunctions::print("Body B Mass: ", body_b->get_mass());
            //UtilityFunctions::print("Body B Inertia Tensor: ", body_b->get_inverse_world_inertia_tensor().inverse());
        }

        // 2. Contact normal
        //UtilityFunctions::print("Contact Normal: ", collision_normal);

        // 3. Center of mass of each body
        //UtilityFunctions::print("Body A Center of Mass: ", body_a->get_center_of_mass_global());
        if (!manifold.body_b_is_static && body_b) {
            //UtilityFunctions::print("Body B Center of Mass: ", body_b->get_center_of_mass_global());
        }

        // 4. Contact points on each body
        //UtilityFunctions::print("Contact Point: ", contact_point);

        // 5. Linear and angular velocities before collision
        //UtilityFunctions::print("Body A Linear Velocity Before Collision: ", body_a->get_velocity());
        //UtilityFunctions::print("Body A Angular Velocity Before Collision: ", body_a->get_angular_velocity());
        if (!manifold.body_b_is_static && body_b) {
            //UtilityFunctions::print("Body B Linear Velocity Before Collision: ", body_b->get_velocity());
            //UtilityFunctions::print("Body B Angular Velocity Before Collision: ", body_b->get_angular_velocity());
        }

        // 6. r1 and r2 values
        //UtilityFunctions::print("r1 (Body A): ", ra);
        if (!manifold.body_b_is_static && body_b) {
            //UtilityFunctions::print("r2 (Body B): ", rb);
        }

        // 7. Coefficient of restitution used
        //UtilityFunctions::print("Coefficient of Restitution: ", restitution);

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

        // **8. Impulse value (lambda) - momentum transferred**
        //UtilityFunctions::print("Impulse Scalar (j): ", j);

        // Apply impulse
        Vector3 impulse = collision_normal * j;

        // **Print impulse vector**
        //UtilityFunctions::print("Impulse Vector: ", impulse);

        // Apply Linear and Angular impulse to body A
        body_a->apply_impulse_off_centre(impulse, ra);

        // Apply impulse to body B if it's not static and not null
        if (!manifold.body_b_is_static && body_b) {
            body_b->apply_impulse_off_centre(-impulse, rb);
        }

        // **Values of linear and angular velocity after collision**
        //UtilityFunctions::print("\n=== After Collision ===");
        //UtilityFunctions::print("Body A Linear Velocity After Collision: ", body_a->get_velocity());
        //UtilityFunctions::print("Body A Angular Velocity After Collision: ", body_a->get_angular_velocity());
        if (!manifold.body_b_is_static && body_b) {
            //UtilityFunctions::print("Body B Linear Velocity After Collision: ", body_b->get_velocity());
            //UtilityFunctions::print("Body B Angular Velocity After Collision: ", body_b->get_angular_velocity());
        }
    }
}

