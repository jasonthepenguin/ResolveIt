#ifndef I_COLLISION_RESOLVER_H
#define I_COLLISION_RESOLVER_H

#include "i_collision_detector.h"

namespace godot {

/**
 * @brief Interface for collision resolution systems
 */
class ICollisionResolver {
public:
    virtual ~ICollisionResolver() = default;
    
    virtual void set_parameters(float p_correction_percent, float p_position_slop, float p_epsilon) = 0;
    virtual void resolve_collisions(double delta, int impulse_iterations) = 0;
    virtual void apply_positional_corrections() = 0;
    virtual void set_collision_detector(ICollisionDetector* detector) = 0;
};


}

#endif // I_COLLISION_RESOLVER_H