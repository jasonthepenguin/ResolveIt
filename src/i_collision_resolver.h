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
    
    virtual void set_parameters(float correction_percent, float position_slop, float epsilon) = 0;
    virtual void ResolveCollisions(double delta, int impulse_iterations) = 0;
    virtual void ApplyPositionalCorrections() = 0;
    virtual void set_collision_detector(ICollisionDetector* detector) = 0;
};

}

#endif // I_COLLISION_RESOLVER_H