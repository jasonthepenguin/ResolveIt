#ifndef MANIFOLD_H
#define MANIFOLD_H

#include <godot_cpp/variant/vector3.hpp>
#include <vector>

namespace godot {

class RigidBodyCustom;

struct Manifold {
    RigidBodyCustom* body_a;
    RigidBodyCustom* body_b;
    std::vector<Vector3> contact_points;
    std::vector<Vector3> collision_normals;
    std::vector<float> penetrations;
    bool body_b_is_static;
};

struct ManifoldKey {
    RigidBodyCustom* body_a;
    RigidBodyCustom* body_b;

    bool operator==(const ManifoldKey& other) const {
        return body_a == other.body_a && body_b == other.body_b;
    }
};

struct ManifoldKeyHash {
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