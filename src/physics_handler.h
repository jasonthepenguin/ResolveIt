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


#include <map>
#include <unordered_map>

#include <godot_cpp/classes/engine.hpp>
#include<godot_cpp/classes/static_body3d.hpp>

#include "manifold.h"

#include "collision_detector.h"
#include "collision_resolver.h"

// Forward declaration of RigidBodyCustom
namespace godot{
    class RigidBodyCustom;
}


namespace godot {









    class PhysicsHandler : public Node3D {
        GDCLASS(PhysicsHandler, Node3D)

        private:

            std::vector<RigidBodyCustom*> rigid_bodies;
            std::map<RID, StaticBody3D*> static_rid_map;
            std::map<RID, RigidBodyCustom*> rid_map;

            PhysicsServer3D *physics_server;
            std::unique_ptr<CollisionDetector> collision_detector;
            std::unique_ptr<CollisionResolver> collision_resolver;

            // constants
            // pos correction consts
            float correction_percent = 0.05f; 
            float position_slop = 0.01f; 
            float epsilon = 0.0001f;
            int impulse_iterations = 1; //= 5;

            


        protected:
            static void _bind_methods();


        public:

                static PhysicsHandler* singleton;

                void register_rigidbody(RigidBodyCustom* rigid_body);
                void deregister_rigidbody(RigidBodyCustom* rigid_body);


                PhysicsHandler();
                ~PhysicsHandler();


                Array get_rigid_bodies() const;
    
                void _ready() override;
                void _physics_process(double delta) override;
                void gather_bodies();


                void integrate_all_body_forces(double delta);

                void apply_gravity_forces();

                void update_server_transforms();

                void set_correction_percent(float p_value);
                float get_correction_percent() const;
                
                void set_position_slop(float p_value);
                float get_position_slop() const;
                
                void set_collision_epsilon(float p_value);
                float get_collision_epsilon() const;
                
                void set_impulse_iterations(int p_value);
                int get_impulse_iterations() const;
                
                
                


                


                
    };

}




#endif // PHYSICS_HANDLER_H
