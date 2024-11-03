/**
 * @file collision_detector.h
 * @brief Defines the CollisionDetector class for handling 3D physics collision detection
 * @author Jason Botterill
 */

#ifndef COLLISION_DETECTOR_H
#define COLLISION_DETECTOR_H

#include <godot_cpp/classes/physics_server3d.hpp>
#include <unordered_map>
#include "rigid_body_custom.h"
#include "manifold.h" 


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


#include "i_collision_detector.h"

namespace godot{

/**
 * @class CollisionDetector
 * @brief A class that handles collision detection between rigid bodies in a 3D physics environment.
 * 
 * @details CollisionDetector implements the ICollisionDetector interface and works with 
 * Godot's PhysicsServer3D to detect and manage collisions between RigidBodyCustom objects. 
 * It maintains a collection of collision manifolds that describe the contact points between 
 * colliding bodies.
 * 
 * The detector uses Godot's built-in physics engine collision detection information 
 * to store the contact results in manifolds for use in collision 
 * resolution.
 * 
 * @implements ICollisionDetector
 */
class CollisionDetector : public ICollisionDetector{
public:
    /**
     * @brief Constructs a CollisionDetector object.
     * @param p_physics_server Pointer to the PhysicsServer3D instance to use for collision detection.
     */
    CollisionDetector(PhysicsServer3D* p_physics_server);
    
    /**
     * @brief Detects collisions between the provided rigid bodies.
     * @param bodies Vector of RigidBodyCustom pointers to check for collisions.
     * @param rid_map Map of RIDs to their corresponding RigidBodyCustom pointers.
     */
    void DetectCollisions(
        const std::vector<RigidBodyCustom*>& bodies,
        const std::map<RID, RigidBodyCustom*>& rid_map
    );

    /**
     * @brief Clears all stored collision manifolds.
     */
    void ClearManifolds();

    /**
     * @brief Gets the map of collision manifolds.
     * @return Reference to the unordered map containing all collision manifolds.
     */
    std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& get_manifold_map();

private:
    PhysicsServer3D* physics_server_; 
    std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash> manifold_map_; 
};


}



#endif // COLLISION_DETECTOR_H
