#ifndef I_COLLISION_DETECTOR_H
#define I_COLLISION_DETECTOR_H

#include <vector>
#include <map>
#include <unordered_map>
#include <godot_cpp/variant/rid.hpp>
#include "manifold.h"

namespace godot {

// forward declaration
class RigidBodyCustom;

/**
 * @brief Interface for collision detection systems
 */
class ICollisionDetector {
public:
    virtual ~ICollisionDetector() = default;
    
    virtual void DetectCollisions(
        const std::vector<RigidBodyCustom*>& bodies,
        const std::map<RID, RigidBodyCustom*>& rid_map
    ) = 0;
    
    virtual void ClearManifolds() = 0;
    
    virtual std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& get_manifold_map() = 0;
};

}

#endif // I_COLLISION_DETECTOR_H