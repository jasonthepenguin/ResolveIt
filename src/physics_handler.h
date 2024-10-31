#ifndef PHYSICS_HANDLER_H
#define PHYSICS_HANDLER_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/rid.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/variant/array.hpp>


#include <map>
#include <unordered_map>

#include <godot_cpp/classes/engine.hpp>
#include<godot_cpp/classes/static_body3d.hpp>

#include "manifold.h"

#include "i_collision_detector.h"
#include "i_collision_resolver.h"

#include "collision_detector.h"
#include "collision_resolver.h"

// Forward declaration of RigidBodyCustom
namespace godot{
    class RigidBodyCustom;
}


namespace godot {

    /**
     * @brief Physics simulation handler for custom rigid body physics
     * 
     * PhysicsHandler manages the physics simulation for custom rigid bodies in a 3D space.
     * It handles collision detection, resolution, and physics integration for both dynamic
     * and static bodies.
     */
    class PhysicsHandler : public Node3D {
        GDCLASS(PhysicsHandler, Node3D)

        private:
            /** @brief List of all registered rigid bodies in the simulation */
            std::vector<RigidBodyCustom*> rigid_bodies;
            /** @brief Mapping of RIDs to static bodies */
            std::map<RID, StaticBody3D*> static_rid_map;
            /** @brief Mapping of RIDs to rigid bodies */
            std::map<RID, RigidBodyCustom*> rid_map;

            /** @brief Reference to the physics server */
            PhysicsServer3D *physics_server;
            /** @brief Handles collision detection between bodies */
            std::unique_ptr<ICollisionDetector> collision_detector;
            /** @brief Handles resolution of detected collisions */
            std::unique_ptr<ICollisionResolver> collision_resolver;

            // Position correction constants
            /** @brief Percentage of intersection resolution per frame (0-1) */
            float correction_percent = 0.05f;
            /** @brief Minimum penetration distance before correction is applied */
            float position_slop = 0.01f;
            /** @brief Small number for floating-point comparisons */
            float epsilon = 0.0001f;
            /** @brief Number of iterations for impulse resolution */
            int impulse_iterations = 1;

        protected:
            static void _bind_methods();

        public:
            /** @brief Singleton instance of the physics handler */
            static PhysicsHandler* singleton;

            /**
             * @brief Registers a rigid body with the physics handler
             * @param rigid_body The rigid body to register
             */
            void register_rigidbody(RigidBodyCustom* rigid_body);

            /**
             * @brief Removes a rigid body from the physics handler
             * @param rigid_body The rigid body to deregister
             */
            void deregister_rigidbody(RigidBodyCustom* rigid_body);

            PhysicsHandler();
            ~PhysicsHandler();

            /**
             * @brief Gets all registered rigid bodies
             * @return Array of rigid bodies
             */
            Array get_rigid_bodies() const;
    
            /**
             * @brief Called when the node enters the scene tree
             */
            void _ready() override;

            /**
             * @brief Called every physics frame
             * @param delta Time since last physics frame
             */
            void _physics_process(double delta) override;

            /**
             * @brief Updates internal list of physics bodies
             */
            void gather_bodies();

            /**
             * @brief Integrates forces for all registered bodies
             * @param delta Time step for integration
             */
            void integrate_all_body_forces(double delta);

            /**
             * @brief Applies gravity to all bodies
             */
            void apply_gravity_forces();

            /**
             * @brief Updates transforms in the physics server
             */
            void update_server_transforms();

            // Getters and setters for physics parameters
            /**
             * @brief Sets the correction percentage for position resolution
             * @param p_value Correction percentage (0-1)
             */
            void set_correction_percent(float p_value);
            float get_correction_percent() const;
            
            /**
             * @brief Sets the position slop threshold
             * @param p_value Minimum penetration distance
             */
            void set_position_slop(float p_value);
            float get_position_slop() const;
            
            /**
             * @brief Sets the epsilon value for floating-point comparisons
             * @param p_value Epsilon value
             */
            void set_collision_epsilon(float p_value);
            float get_collision_epsilon() const;
            
            /**
             * @brief Sets the number of impulse resolution iterations
             * @param p_value Number of iterations
             */
            void set_impulse_iterations(int p_value);
            int get_impulse_iterations() const;
    };
}




#endif // PHYSICS_HANDLER_H
