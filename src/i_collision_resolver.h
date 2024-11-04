/**
 * @file i_collision_resolver.h
 * @brief Defines the interface for collision resolution systems
 * @author Jason Botterill
 */

#ifndef I_COLLISION_RESOLVER_H
#define I_COLLISION_RESOLVER_H

#include "i_collision_detector.h"

namespace godot {

/**
 * @brief Interface for collision resolution systems
 * 
 * This interface defines the contract for collision resolution implementations.
 * It provides methods for configuring resolution parameters, resolving collisions,
 * applying positional corrections, and setting the collision detector.
 */
class ICollisionResolver {
public:
    virtual ~ICollisionResolver() = default;
    
    /**
     * @brief Sets the parameters for collision resolution
     * @param correction_percent Percentage of correction to apply (0.0 to 1.0)
     * @param position_slop Allowed penetration depth before correction
     * @param epsilon Small number for floating-point comparisons
     */
    virtual void set_parameters(float correction_percent, float position_slop, float epsilon) = 0;

    /**
     * @brief Resolves collisions between objects
     * @param delta Time step for the physics update
     * @param impulse_iterations Number of iterations for impulse resolution
     */
    virtual void ResolveCollisions(double delta, int impulse_iterations) = 0;

    /**
     * @brief Applies position corrections to resolve penetration
     */
    virtual void ApplyPositionalCorrections() = 0;

    /**
     * @brief Sets the collision detector to be used for resolution
     * @param detector Pointer to the collision detector implementation
     */
    virtual void set_collision_detector(ICollisionDetector* detector) = 0;
};

}

#endif // I_COLLISION_RESOLVER_H