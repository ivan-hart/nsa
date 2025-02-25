package ecs

// core library imports
import "core:fmt"
import "core:sync"
import "core:thread"

// the entity type of an unsigned 64 bit integer
Entity :: distinct u64

// the struct where we'll be storing all of the information of components added to the register
ComponentStorage :: struct {
	type:        typeid,
	data:        rawptr,
	delete_proc: proc(data: rawptr),
}

// the register of the ECS system
Registry :: struct {
	entities:   [dynamic]Entity,
	components: map[typeid]ComponentStorage,
}

// called at the start of the lifecycle of the program/ ECS instance to initalize the maps and arrays
registry_init :: proc(registry: ^Registry) {
	registry.entities = make([dynamic]Entity)
	registry.components = make(map[typeid]ComponentStorage)
}

// called near the end of the lifespan of the application to clean up memory
registry_destroy :: proc(registry: ^Registry) {
	delete(registry.entities)
	for _, storage in registry.components {
		storage.delete_proc(storage.data)
	}
	delete(registry.components)
}

// creates an entity always making sure that duplicates can't exist
registry_create_entity :: proc(registry: ^Registry) -> Entity {
	@(static) id_counter: u64 = 0
	id_counter += 1
	entity := Entity(id_counter)
	append(&registry.entities, entity)
	return entity
}

// adds a component to an entity
registry_add_component :: proc(registry: ^Registry, entity: Entity, component: $T) {
	tid := typeid_of(T)
	if tid not_in registry.components {
		m := new(map[Entity]T)
		m^ = make(map[Entity]T)
		delete_proc :: proc(data: rawptr) {
			m := cast(^map[Entity]T)data
			delete(m^)
			free(m)
		}
		registry.components[tid] = ComponentStorage {
			type        = tid,
			data        = m,
			delete_proc = delete_proc,
		}
	}
	storage := &registry.components[tid]
	m := cast(^map[Entity]T)storage.data
	m^[entity] = component
}

// retrevies a component of the selected entity
registry_get_component :: proc(registry: ^Registry, entity: Entity, $T: typeid) -> ^T {
	tid := typeid_of(T)
	if tid not_in registry.components {
		return nil
	}
	storage := registry.components[tid]
	m := cast(^map[Entity]T)storage.data
	if entity not_in m^ {
		return nil
	}
	return &m^[entity]
}
