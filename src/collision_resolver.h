#ifndef COLLISION_RESOLVER_H
#define COLLISION_RESOLVER_H

#include "manifold.h"
#include "collision_detector.h"
#include "rigid_body_custom.h"
#include <unordered_map>

namespace godot {

class CollisionResolver {
public:
    CollisionResolver();
    
    void set_parameters(float p_correction_percent, float p_position_slop, float p_epsilon);
    void resolve_collisions(double delta, int impulse_iterations);
    void apply_positional_corrections();
    void set_collision_detector(CollisionDetector* detector) { collision_detector = detector; }

private:
    void resolve_collision(Manifold& manifold, double delta);
    
    float correction_percent = 0.05f;
    float position_slop = 0.01f;
    float epsilon = 0.0001f;
    CollisionDetector* collision_detector = nullptr;
};

}

#endif // COLLISION_RESOLVER_H
