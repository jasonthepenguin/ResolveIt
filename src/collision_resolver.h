/**
 * @file collision_resolver.h
 * @author Jason Botterill
 * @brief Header file for the CollisionResolver class that handles physics collision resolution
 * @details This file contains the declaration of the CollisionResolver class, which is responsible
 *          for resolving physical collisions between rigid bodies in the physics simulation.
 *          It works in conjunction with the collision detection system to apply appropriate
 *          impulses and position corrections.
 */

#ifndef COLLISION_RESOLVER_H
#define COLLISION_RESOLVER_H

#include "manifold.h"
#include "collision_detector.h"
#include "rigid_body_custom.h"
#include <unordered_map>

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/time.hpp>


#include "i_collision_resolver.h"

namespace godot {

/**
 * @brief Handles the resolution of collisions between rigid bodies
 * 
 * The CollisionResolver class is responsible for resolving collisions between rigid bodies
 * by applying impulses and positional corrections. It works in conjunction with the
 * CollisionDetector to handle physics simulation responses.
 */
class CollisionResolver : public ICollisionResolver{
public:
    /** @brief Default constructor */
    CollisionResolver();
    
    /**
     * @brief Sets the parameters for collision resolution
     * @param correction_percent Percentage of penetration to correct per frame [0,1]
     * @param position_slop Small overlap allowed between objects before correction
     * @param epsilon Small value used for floating-point comparisons
     */
    void set_parameters(float correction_percent, float position_slop, float epsilon);

    /**
     * @brief Resolves all detected collisions
     * @param delta Time step for the physics update
     * @param impulse_iterations Number of iterations for impulse resolution
     */
    void ResolveCollisions(double delta, int impulse_iterations);

    /**
     * @brief Applies position corrections to resolve penetration between bodies
     */
    void ApplyPositionalCorrections();

    /**
     * @brief Sets the collision detector to be used for resolution
     * @param detector Pointer to the collision detector instance
     */
    void set_collision_detector(ICollisionDetector* detector) { collision_detector_ = detector; }

    /**
     * @brief Logs the current state of a collision for debugging purposes
     * @param phase Current phase of collision resolution being logged
     * @param manifold Collision manifold containing contact information
     * @param contact_point Point of contact between colliding bodies
     * @param collision_normal Normal vector at the point of collision
     * @param restitution Coefficient of restitution for the collision
     * @param delta Time step for the physics update
     */
    void LogCollisionState(const char* phase, 
                           const Manifold& manifold,
                           const Vector3& contact_point,
                           const Vector3& collision_normal,
                           float restitution,
                           double delta);


private:
    /**
     * @brief Resolves a single collision between two bodies
     * @param manifold Collision manifold containing contact information
     * @param delta Time step for the physics update
     */
    void ResolveCollision(Manifold& manifold, double delta);
    
    float correction_percent_ = 0.05f;  ///< Percentage of penetration to correct per frame
    float position_slop_ = 0.01f;      ///< Small overlap allowed before position correction
    float epsilon_ = 0.0001f;          ///< Small value for floating-point comparisons
    ICollisionDetector* collision_detector_ = nullptr;  ///< Pointer to the collision detector
};

}

#endif // COLLISION_RESOLVER_H
