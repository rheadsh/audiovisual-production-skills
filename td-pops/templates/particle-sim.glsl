// ============================================
// PARTICLE SIMULATION TEMPLATE
// Position + velocity integration with forces
// ============================================

// UNIFORMS
uniform float uDeltaTime;
uniform vec3  uGravity;
uniform float uDamping;

// CONSTANTS
const float EPSILON = 0.0001;

// HELPER FUNCTIONS
vec3 applyForce(vec3 pos, vec3 vel, vec3 force, float dt) {
    return vel + force * dt;
}

// MAIN
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    vec3 vel = TDIn_v();

    // Apply forces
    vel = applyForce(pos, vel, uGravity, uDeltaTime);

    // Damping
    vel *= uDamping;

    // Integrate position
    pos += vel * uDeltaTime;

    // Write outputs
    P[id] = pos;
    v[id] = vel;
}
