#ifndef COLLISION_RESOLVER_H
#define COLLISION_RESOLVER_H

#include "manifold.h"
#include "collision_detector.h"
#include "rigid_body_custom.h"
#include <unordered_map>

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
     * @param p_correction_percent Percentage of penetration to correct per frame [0,1]
     * @param p_position_slop Small overlap allowed between objects before correction
     * @param p_epsilon Small value used for floating-point comparisons
     */
    void set_parameters(float p_correction_percent, float p_position_slop, float p_epsilon);

    /**
     * @brief Resolves all detected collisions
     * @param delta Time step for the physics update
     * @param impulse_iterations Number of iterations for impulse resolution
     */
    void resolve_collisions(double delta, int impulse_iterations);

    /**
     * @brief Applies position corrections to resolve penetration between bodies
     */
    void apply_positional_corrections();

    /**
     * @brief Sets the collision detector to be used for resolution
     * @param detector Pointer to the collision detector instance
     */
    void set_collision_detector(ICollisionDetector* detector) { collision_detector = detector; }

private:
    /**
     * @brief Resolves a single collision between two bodies
     * @param manifold Collision manifold containing contact information
     * @param delta Time step for the physics update
     */
    void resolve_collision(Manifold& manifold, double delta);
    
    float correction_percent = 0.05f;  ///< Percentage of penetration to correct per frame
    float position_slop = 0.01f;      ///< Small overlap allowed before position correction
    float epsilon = 0.0001f;          ///< Small value for floating-point comparisons
    //CollisionDetector* collision_detector = nullptr;  ///< Pointer to the collision detector
    ICollisionDetector* collision_detector = nullptr;  ///< Pointer to the collision detector
};

}

#endif // COLLISION_RESOLVER_H
