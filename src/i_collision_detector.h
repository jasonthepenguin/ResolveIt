/**
 * @file i_collision_detector.h
 * @brief Defines the interface for collision detection systems
 * @author Jason Botterill
 */

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
 * 
 * This interface defines the contract for collision detection implementations.
 * It provides methods for detecting collisions between rigid bodies and managing
 * collision manifolds.
 */
class ICollisionDetector {
public:
    /**
     * @brief Virtual destructor for proper cleanup of derived classes
     */
    virtual ~ICollisionDetector() = default;
    
    /**
     * @brief Detects collisions between the provided rigid bodies
     * @param bodies Vector of pointers to rigid bodies to check for collisions
     * @param rid_map Map of RIDs to their corresponding rigid bodies
     */
    virtual void DetectCollisions(
        const std::vector<RigidBodyCustom*>& bodies,
        const std::map<RID, RigidBodyCustom*>& rid_map
    ) = 0;
    
    /**
     * @brief Clears all stored collision manifolds
     */
    virtual void ClearManifolds() = 0;
    
    /**
     * @brief Gets the map of collision manifolds
     * @return Reference to the unordered map containing collision manifolds
     */
    virtual std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& get_manifold_map() = 0;
};

}

#endif // I_COLLISION_DETECTOR_H