#ifndef MANIFOLD_H
#define MANIFOLD_H

#include <godot_cpp/variant/vector3.hpp>
#include <vector>

namespace godot {

class RigidBodyCustom;

/**
 * @brief Contains collision information between two rigid bodies
 * 
 * Stores contact points, collision normals, and penetration depths for a collision
 * between two rigid bodies. Also tracks whether the second body is static.
 */
struct Manifold {
    RigidBodyCustom* body_a;              ///< First body involved in the collision
    RigidBodyCustom* body_b;              ///< Second body involved in the collision
    std::vector<Vector3> contact_points;   ///< Points where the bodies are in contact
    std::vector<Vector3> collision_normals;///< Normal vectors at each contact point
    std::vector<float> penetrations;       ///< Penetration depths at each contact point
    bool body_b_is_static;                 ///< Whether body_b is a static body
};

/**
 * @brief Key structure for identifying unique body pairs in collision
 * 
 * Used as a key in collision manifold lookups to identify unique pairs
 * of colliding bodies.
 */
struct ManifoldKey {
    RigidBodyCustom* body_a;              ///< First body in the pair
    RigidBodyCustom* body_b;              ///< Second body in the pair

    /**
     * @brief Equality comparison operator
     * @param other The ManifoldKey to compare with
     * @return true if both body pointers match
     */
    bool operator==(const ManifoldKey& other) const {
        return body_a == other.body_a && body_b == other.body_b;
    }
};

/**
 * @brief Hash function object for ManifoldKey
 * 
 * Provides a hash function for ManifoldKey to enable its use in 
 * unordered containers.
 */
struct ManifoldKeyHash {
    /**
     * @brief Hash operator for ManifoldKey
     * @param key The ManifoldKey to hash
     * @return A hash value for the key
     */
    size_t operator()(const ManifoldKey& key) const {
        // If body_b is nullptr (static body), only hash body_a
        if (key.body_b == nullptr) {
            return std::hash<RigidBodyCustom*>()(key.body_a);
        }
        // Otherwise, hash both bodies using XOR (^)
        return std::hash<RigidBodyCustom*>()(key.body_a) ^ 
               std::hash<RigidBodyCustom*>()(key.body_b);
    }
};

} 

#endif // MANIFOLD_H