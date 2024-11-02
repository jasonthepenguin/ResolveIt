#include "collision_resolver.h"
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

CollisionResolver::CollisionResolver() {}

void CollisionResolver::set_parameters(float correction_percent, float position_slop, float epsilon) {
    correction_percent_ = correction_percent;
    position_slop_ = position_slop;
    epsilon_ = epsilon;
}

void CollisionResolver::ResolveCollisions(double delta, int impulse_iterations) {
    if (!collision_detector_) return;
    
    auto& manifold_map = collision_detector_->get_manifold_map();
    for(int i = 0; i < impulse_iterations; ++i) {
        for (auto& pair : manifold_map) {
            // Use reference to modify the original manifold
            Manifold& manifold = pair.second;
            ResolveCollision(manifold, delta);
        }
    }
}

void CollisionResolver::ApplyPositionalCorrections() {
    
    if(!collision_detector_) return;

    auto& manifold_map = collision_detector_->get_manifold_map();
    
    for (const auto& pair : manifold_map) {
        const Manifold& manifold = pair.second;
        RigidBodyCustom* body_a = manifold.body_a;
        RigidBodyCustom* body_b = nullptr;
        float body_b_mass = INFINITY;

        if (!manifold.body_b_is_static) {
            body_b = manifold.body_b;
            if (body_b) {
                body_b_mass = body_b->get_mass();
            }
        }

        for (size_t i = 0; i < manifold.contact_points.size(); ++i) {
            float penetration = manifold.penetrations[i];
            ////UtilityFunctions::print(penetration);
            if (std::abs(penetration) > position_slop_ ) {
                Vector3 correction = manifold.collision_normals[i] * (penetration - position_slop_) * correction_percent_;

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



void CollisionResolver::ResolveCollision(Manifold& manifold, double delta) {
    // Get the two colliding bodies
    RigidBodyCustom* body_a = manifold.body_a;     // Body 1 in equation
    RigidBodyCustom* body_b = manifold.body_b;     // Body 2 in equation

    // Initialize body B properties (handling static case)
    Vector3 body_b_velocity = Vector3();           // V₂ if static
    Vector3 body_b_angular_velocity = Vector3();   // ω₂ if static
    float body_b_inv_mass = 0.0f;                 // 1/m₂ if static
    float body_b_restitution = 1.0f;              // ε for body 2

    // Get body B properties if it's not static
    if (!manifold.body_b_is_static && body_b) {
        body_b_velocity = body_b->get_velocity();           // V₂
        body_b_angular_velocity = body_b->get_angular_velocity(); // ω₂
        body_b_inv_mass = body_b->get_inv_mass();          // 1/m₂
        body_b_restitution = body_b->get_restitution();    // ε
    }

    for (size_t i = 0; i < manifold.contact_points.size(); ++i) {
        Vector3 collision_normal = manifold.collision_normals[i];    // n̂ (unit normal)
        Vector3 contact_point = manifold.contact_points[i];

        // NUMERATOR 
        // first doing most inner bracket calculations
        Vector3 linear_rel_vel = body_a->get_velocity() - body_b_velocity;

        // r₁ and r₂ vectors (from center of mass to contact point)
        Vector3 r1 = contact_point - body_a->get_center_of_mass_global();  // r₁
        Vector3 r2 = manifold.body_b_is_static ? Vector3() 
                    : contact_point - body_b->get_center_of_mass_global(); // r₂
        
        Vector3 r1_x_n = r1.cross(collision_normal);
        Vector3 r2_x_n = r2.cross(collision_normal);

        double minus_one_plus_e = -(1 + MIN(body_a->get_restitution(), body_b_restitution) );
        // *
        double n_x_linear_rel_vel = linear_rel_vel.dot(collision_normal);
        // + 
        double w1_dot_r1_x_n = body_a->get_angular_velocity().dot(r1_x_n);
        // - 
        double w2_dot_r2_x_n = body_b_angular_velocity.dot(r2_x_n);

        double numerator = minus_one_plus_e * n_x_linear_rel_vel + w1_dot_r1_x_n - w2_dot_r2_x_n;

        // DENOMINATOR
        // 1/m1 + 1/m2
        double inv_mass_sum = body_a->get_inv_mass() + body_b_inv_mass;

        // rotational contribution from body A
        Vector3 j1_inv_r1_x_n = body_a->get_inverse_world_inertia_tensor().xform(r1_x_n);

        double rotational_a = r1_x_n.dot(j1_inv_r1_x_n); // (r₁×n̂)ᵀ J₁⁻¹ (r₁×n̂)

        double rotational_b = 0.0;
        if(!manifold.body_b_is_static)
        {
            Vector3 j2_inv_r2_x_n = body_b->get_inverse_world_inertia_tensor().xform(r2_x_n);
            rotational_b = r2_x_n.dot(j2_inv_r2_x_n);
        }
        
        double denominator = inv_mass_sum + rotational_a + rotational_b;

        // Avoid division by zero
        if (fabs(denominator) < epsilon_) {
            continue;
        }

        double lambda = numerator / denominator;
        Vector3 impulse = collision_normal * lambda; // Final impulse vector

        // Apply the impulses to both bodies
        body_a->ApplyImpulseOffCentre(impulse, r1);
        if (!manifold.body_b_is_static && body_b) {
            body_b->ApplyImpulseOffCentre(-impulse, r2);
        }
    }
}

void CollisionResolver::LogCollisionState(const char* phase,
                                          const Manifold& manifold,
                                          const Vector3& contact_point,
                                          const Vector3& collision_normal,
                                          float restitution,
                                          double delta) {

    
    
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
    

}