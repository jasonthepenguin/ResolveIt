

#include "collision_detector.h"
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/node.hpp>

using namespace godot;


CollisionDetector::CollisionDetector(PhysicsServer3D* p_physics_server)
    : physics_server(p_physics_server) {
}

void CollisionDetector::detect_collisions(
    const std::vector<RigidBodyCustom*>& bodies,
    const std::map<RID, RigidBodyCustom*>& rid_map
) {
    for (auto* rigid_body : bodies) {
        PhysicsDirectBodyState3D* state = physics_server->body_get_direct_state(rigid_body->get_body_rid());
        if (!state) continue;

        int contact_count = state->get_contact_count();
        for (int i = 0; i < contact_count; ++i) {
            Vector3 collision_normal = state->get_contact_local_normal(i).normalized();
            RID other_rid = state->get_contact_collider(i);
            Vector3 collision_point = state->get_contact_local_position(i);

            Object* obj = ObjectDB::get_instance(state->get_contact_collider_id(i));
            Node* other_node = Object::cast_to<Node>(obj);
            
            RigidBodyCustom* other_body = nullptr;
            bool other_is_static = true;

            auto it = rid_map.find(other_rid);

            if (it != rid_map.end()) {
                other_body = it->second;
                other_is_static = false;
            } else if (other_node && other_node->is_class("StaticBody3D")) {
                other_is_static = true;
                other_body = nullptr;
            } else {
                other_is_static = true;
                other_body = nullptr;
            }

            ManifoldKey key{rigid_body, other_body};

            Vector3 penetration_vector = state->get_contact_local_position(i) - state->get_contact_collider_position(i);
            float penetration_depth = penetration_vector.dot(collision_normal);

            auto manifold_it = manifold_map.find(key);
            if (manifold_it == manifold_map.end()) {
                Manifold manifold;
                manifold.body_a = rigid_body;
                manifold.body_b = other_body;
                manifold.body_b_is_static = other_is_static;
                manifold.contact_points.push_back(collision_point);
                manifold.collision_normals.push_back(collision_normal);
                manifold.penetrations.push_back(penetration_depth);
                manifold_map[key] = manifold;
            } else {
                Manifold& manifold = manifold_it->second;
                manifold.contact_points.push_back(collision_point);
                manifold.collision_normals.push_back(collision_normal);
                manifold.penetrations.push_back(penetration_depth);
            }
        }
    }
}

std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& CollisionDetector::get_manifold_map() {
    return manifold_map;
}


void CollisionDetector::clear_manifolds() {
    manifold_map.clear();
}