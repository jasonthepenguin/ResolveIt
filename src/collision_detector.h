#ifndef COLLISION_DETECTOR_H
#define COLLISION_DETECTOR_H

#include <godot_cpp/classes/physics_server3d.hpp>
#include <unordered_map>
#include "rigid_body_custom.h"
#include "manifold.h" // Assuming you'll move Manifold struct to its own header


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

namespace godot{

class CollisionDetector {
public:
    CollisionDetector(PhysicsServer3D* p_physics_server);
    
    void detect_collisions(
        const std::vector<RigidBodyCustom*>& bodies,
        const std::map<RID, RigidBodyCustom*>& rid_map,
        std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& manifold_map
    );

private:
    PhysicsServer3D* physics_server;
};


}



#endif // COLLISION_DETECTOR_H
