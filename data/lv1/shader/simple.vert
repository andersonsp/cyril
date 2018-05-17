in vec2 Position;
in vec3 InColor;
out vec3 OutColor;

void main() {
    OutColor = InColor;
    gl_Position = vec4(Position, 0, 1);
}
