/**
 * @file physics_handler.h
 * @brief Custom physics simulation handler for rigid body dynamics
 * 
 * @details
 * This file contains the PhysicsHandler class definition, which manages the core
 * physics simulation pipeline in the custom physics system. It handles:
 * - Registration and management of rigid and static bodies
 * - Collision detection and resolution
 * - Force integration and position updates
 * - Synchronization with Godot's physics server
 * 
 * The implementation follows a modular design with separate collision detection
 * and resolution systems, allowing for easy extension and modification of the
 * physics behavior.
 * 
 * @author Jason Botterill
 * @date 2024
 */


/** @mainpage ResolveIt Physics Engine
 *  A custom physics simulation engine integrated with Godot
 *
 *  @section overview System Overview
 *  This physics engine provides custom rigid body dynamics simulation with:
 *  - Custom collision detection and resolution
 *  - Force integration system
 *  - Godot engine integration
 *  
 *  @section structure Core Architecture
 *  @dot
 *  digraph CoreStructure {
 *      node [shape=box];
 *      PhysicsHandler -> RigidBodyCustom;
 *      PhysicsHandler -> ICollisionDetector;
 *      PhysicsHandler -> ICollisionResolver;
 *  }
 *  @enddot
 *
 *  Detailed class relationships can be found in the Class Hierarchy and 
 *  Class Collaboration sections under the Classes tab.
 */


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
     * @details
     * PhysicsHandler is responsible for managing the complete physics simulation pipeline:
     * - Maintains a registry of dynamic (RigidBodyCustom) and static bodies
     * - Performs collision detection between bodies using ICollisionDetector
     * - Resolves detected collisions using ICollisionResolver
     * - Handles physics integration and force application
     * - Manages position correction and impulse resolution
     * - Synchronizes physics state with Godot's PhysicsServer3D
     * 
     * The handler operates on a fixed timestep during physics processing and provides
     * configurable parameters for fine-tuning collision response and position correction.
     * 
     * Implementation structure inspired by "Game Physics Cookbook" by Gabor Szauer, with
     * significant modifications for Godot integration and custom requirements.
     * 
     * @author Jason Botterill
     * 
     * @see RigidBodyCustom
     * @see ICollisionDetector
     * @see ICollisionResolver
     */
    class PhysicsHandler : public Node3D {
        GDCLASS(PhysicsHandler, Node3D)

        private:
            /** @brief List of all registered rigid bodies in the simulation */
            std::vector<RigidBodyCustom*> rigid_bodies_;
            /** @brief Mapping of RIDs to static bodies */
            std::map<RID, StaticBody3D*> static_rid_map_;
            /** @brief Mapping of RIDs to rigid bodies */
            std::map<RID, RigidBodyCustom*> rid_map_;

            /** @brief Reference to the physics server */
            PhysicsServer3D *physics_server_;
            /** @brief Handles collision detection between bodies */
            std::unique_ptr<ICollisionDetector> collision_detector_;
            /** @brief Handles resolution of detected collisions */
            std::unique_ptr<ICollisionResolver> collision_resolver_;

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
            void RegisterRigidbody(RigidBodyCustom* rigid_body);

            /**
             * @brief Removes a rigid body from the physics handler
             * @param rigid_body The rigid body to deregister
             */
            void DeregisterRigidbody(RigidBodyCustom* rigid_body);

            /**
             * @brief Constructs a new Physics Handler instance
             */
            PhysicsHandler();

            /**
             * @brief Destroys the Physics Handler instance and cleans up resources
             */
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
            void GatherBodies();

            /**
             * @brief Integrates forces for all registered bodies
             * @param delta Time step for integration
             */
            void IntegrateAllBodyForces(double delta);

            /**
             * @brief Applies gravity forces to all bodies
             * @details Adds gravitational acceleration to all dynamic bodies in the simulation
             */
            void ApplyGravityForces();

            /**
             * @brief Updates transforms in the physics server
             * @details Synchronizes the physics state with Godot's PhysicsServer3D by updating body transforms
             */
            void UpdateServerTransforms();

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
