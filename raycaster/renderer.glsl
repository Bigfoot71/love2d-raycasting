uniform Image raysBuffer;

uniform Image mapBuffer;
uniform vec2 mapSize;

uniform ArrayImage groundTex;
uniform int groundTexCount;

uniform ArrayImage ceilingTex;
uniform int ceilingTexCount;

uniform ArrayImage wallsTex;
uniform int wallsTexCount;

uniform vec2 pos;
uniform vec2 dir;
uniform vec2 plane;

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

    float wall_y1 = (-rd.wall_height*.5 + love_ScreenSize.y*.5);
    float wall_y2 = (rd.wall_height*.5 + love_ScreenSize.y*.5);

    // Rendering //

    vec4 color; // Final color
    vec4 shade; // Shade (light)

    if (sc.y >= wall_y1 && sc.y <= wall_y2) { // WALLS

        shade = getShade(rd.dist_to_wall);

        if (rd.wall_tex_num <= wallsTexCount) {

            vec2 tex_coord = vec2(                          // Coordinates of the texture sample to display [0->1]
                fract(rd.side == 0 ? rd.hit_y : rd.hit_x),
                (sc.y - wall_y1) / rd.wall_height
            );

            color = Texel(wallsTex, vec3(tex_coord, rd.wall_tex_num)) * shade;

        } else { // Non textured
            color = vec4(1.0) * shade;
        }

    } else { // SKY/CEILING and GROUND

        vec2 ray_dir_0 = dir.xy - plane.xy;
        vec2 ray_dir_1 = dir.xy + plane.xy;

        const float pos_z = 0.5;
        float p, row_distance;
        vec2 step, map_pos;

        if (sc.y < wall_y1) { // SKY/CEILING

            float ceilingTexNum = 0;

            if (ceilingTexNum <= ceilingTexCount) {
                shade = getShade(tc.y*30.0);
                p = (1.0 - tc.y) - pos_z;
                row_distance = pos_z / p;
                step = row_distance * (ray_dir_1 - ray_dir_0);
                map_pos = (pos.xy-1.0) + row_distance * ray_dir_0 + step * tc.x;
                color = Texel(ceilingTex, vec3(fract(map_pos), getMapValue(map_pos/mapSize).g)) * shade;
            } else {
                color = vec4(0.0, 0.1, 0.5, 1.0);
            }

        } else { // GROUND

            float groundTexNum = 0;
            shade = getShade((1.0-tc.y)*30.0);

            if (groundTexNum <= groundTexCount) {
                p = tc.y - pos_z;
                row_distance = pos_z / p;
                step = row_distance * (ray_dir_1 - ray_dir_0);
                map_pos = (pos.xy-1.0) + row_distance * ray_dir_0 + step * tc.x;
                color = Texel(groundTex, vec3(fract(map_pos), getMapValue(map_pos/mapSize).r)) * shade;
            } else {
                color = vec4(0.0, 0.5, 0.1, 1.0) * shade;
            }

        }

    }

    return color;
}