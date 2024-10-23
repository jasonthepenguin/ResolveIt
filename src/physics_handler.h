#ifndef PHYSICS_HANDLER_H
#define PHYSICS_HANDLER_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/variant/rid.hpp>
#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/classes/physics_direct_body_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/variant/array.hpp>
#include "rigid_body_custom.h"
#include <map>
#include <unordered_map>

#include <godot_cpp/classes/engine.hpp>
#include<godot_cpp/classes/static_body3d.hpp>




namespace godot {







    class PhysicsHandler : public Node3D {
        GDCLASS(PhysicsHandler, Node3D)

        private:

            std::vector<RigidBodyCustom*> rigid_bodies;
            std::map<RID, StaticBody3D*> static_rid_map;
            std::map<RID, RigidBodyCustom*> rid_map;

            PhysicsServer3D *physics_server;



        protected:
            static void _bind_methods();


        public:


            // manifolds class
    struct Manifold {
        RigidBodyCustom* body_a;
        //RigidBodyCustom* body_b;
        Node* body_b_node;
        std::vector<Vector3> contact_points;
        std::vector<Vector3> collision_normals;
        std::vector<float> penetrations;
        bool body_b_is_static;
    };

    struct ManifoldKey {
        RigidBodyCustom* body_a;
        //RigidBodyCustom* body_b;
        Node* body_b_node;

        bool operator==(const ManifoldKey& other) const {
            return body_a == other.body_a && body_b_node == other.body_b_node;
                   
        }
    };

    struct ManifoldKeyHash {
        size_t operator()(const ManifoldKey& key) const {
            return std::hash<RigidBodyCustom*>()(key.body_a) ^ std::hash<Node*>()(key.body_b_node);
        }
    };

            
                PhysicsHandler();
                ~PhysicsHandler();
    
                void _ready() override;
                void _physics_process(double delta) override;
                void gather_bodies();


                void integrate_all_body_forces(double delta);

                void detect_and_resolve_collisions(double delta);

                //void resolve_collision(RigidBodyCustom* body_a, RigidBodyCustom* body_b, const Vector3& collision_normal, const Vector3& collision_point , const Vector3& local_contact_point ,  double delta);
                void resolve_collision(Manifold& manifold, double delta);


                void update_server_transforms();

                void apply_positional_corrections(std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& manifold_map);


                //-------
                void find_manifolds(std::unordered_map<ManifoldKey, Manifold, ManifoldKeyHash>& manifold_map);
                


                


                
    };

}




#endif // PHYSICS_HANDLER_H