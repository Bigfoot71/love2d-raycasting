const vec4 skyColor     = vec4(0.0, 0.1, 0.5, 1.0);
const vec4 groundColor  = vec4(0.0, 0.5, 0.1, 1.0);

uniform Image raysBuffer;

uniform Image mapBuffer;
uniform vec2 mapSize;

uniform ArrayImage groundTex;
uniform int groundTexCount;

uniform ArrayImage ceilingTex;
uniform int ceilingTexCount;

uniform ArrayImage wallsTex;
uniform int wallsTexCount;

uniform vec3 pos;
uniform vec2 dir;
uniform vec2 plane;
uniform float pitch;

struct RaysData {

    float hit_x;
    float hit_y;
    float ray_dir_x;
    float ray_dir_y;

    float wall_height;
    float dist_to_wall;
    float side;
    float wall_tex_num;

};

RaysData extractRaysData(float uScreen) {

    RaysData result;

    vec4 l1 = Texel(raysBuffer, vec2(uScreen, .0));

    result.hit_x        = l1.r;
    result.hit_y        = l1.g;
    result.ray_dir_x    = l1.b;
    result.ray_dir_y    = l1.a;

    vec4 l2 = Texel(raysBuffer, vec2(uScreen, 1.));

    result.wall_height  = l2.r;
    result.dist_to_wall = l2.g;
    result.side         = l2.b;
    result.wall_tex_num = l2.a;

    return result;

}

vec4 getMapValue(vec2 mapUV) {
    return Texel(mapBuffer, mapUV);
}

vec4 getShade(float dist) {
    return vec4(vec3(max(1.0-(dist/20.0),.15)),1.0);
}

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {

    // Get raycast data //

    RaysData rd = extractRaysData(tc.x);

    // Get start line and end line of wall //

    float half_wall_height = rd.wall_height*0.5, half_screen_height = love_ScreenSize.y*0.5;
    float wall_y1 = (-half_wall_height + half_screen_height + pitch + (pos.z/rd.dist_to_wall));
    float wall_y2 = (half_wall_height + half_screen_height + pitch + (pos.z/rd.dist_to_wall));

    // Rendering //

    vec4 color; // Final color
    vec4 shade; // Shade (light)

    if (sc.y >= wall_y1 && sc.y <= wall_y2) { // WALLS

        shade = getShade(rd.dist_to_wall);

        if (rd.wall_tex_num < wallsTexCount) {

            vec2 tex_coord = vec2(                          // Coordinates of the texture sample to display [0->1]
                fract(rd.side == 0 ? rd.hit_y : rd.hit_x),
                (sc.y - wall_y1) / rd.wall_height
            );

            color = Texel(wallsTex, vec3(tex_coord, rd.wall_tex_num)) * shade;

        } else { // Non textured
            color = vec4(1.0) * shade;
        }

    } else { // SKY/CEILING and GROUND

        float love_ScreenSize_y_inv = 1.0 / love_ScreenSize.y;
        float pitch_norm = pitch * love_ScreenSize_y_inv;   // Normalize pitch
        float pos_z_norm = pos.z * love_ScreenSize_y_inv;   // Normalize pos.z

        bool is_floor = sc.y > wall_y2;

        vec2 ray_dir_0 = dir.xy - plane.xy;
        vec2 ray_dir_1 = dir.xy + plane.xy;

        float p, cam_z;

        if (is_floor) {
            p = tc.y - 0.5 - pitch_norm;
            cam_z = 0.5 + pos_z_norm;
        } else {
            p = 0.5 - tc.y + pitch_norm;
            cam_z = 0.5 - pos_z_norm;
        }

        float row_distance = cam_z / p;
        vec2 step = row_distance * (ray_dir_1 - ray_dir_0);
        vec2 map_pos = (pos.xy - 1.0) + row_distance * ray_dir_0 + step * tc.x;

        float textureNum;

        if (is_floor) { // FLOOR

            shade = getShade(((1.0-tc.y)+pitch_norm)*30.0);
            textureNum = getMapValue(map_pos/mapSize).r;

            if (textureNum < groundTexCount) {
                color = Texel(groundTex, vec3(fract(map_pos), textureNum)) * shade;
            } else {
                color = groundColor * shade;
            }

        } else { // SKY || CEILING

            textureNum = getMapValue(map_pos/mapSize).g;

            if (textureNum < ceilingTexCount) {
                shade = getShade((tc.y-pitch_norm)*30.0);
                color = Texel(ceilingTex, vec3(fract(map_pos), textureNum)) * shade;
            } else {
                color = skyColor;
            }

        }

    }

    return color;
}