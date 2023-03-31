//precision highp float;

uniform Image dataBuffer;

uniform ArrayImage groundTexs;
uniform int groundTexCount;
uniform int groundTexNum;

uniform ArrayImage wallTexs;
uniform int wallTexCount;

uniform vec2 pos;
uniform vec2 dir;
uniform vec2 plane;

struct RenderData {

    float hit_x;
    float hit_y;
    float ray_dir_x;
    float ray_dir_y;

    float wall_height;
    float dist_to_wall;
    float side;
    float tex_num;

};

RenderData extractRenderData(float uScreen) {

    RenderData result;

    vec4 l1 = Texel(dataBuffer, vec2(uScreen, .0));

    result.hit_x        = l1.r;
    result.hit_y        = l1.g;
    result.ray_dir_x    = l1.b;
    result.ray_dir_y    = l1.a;

    vec4 l2 = Texel(dataBuffer, vec2(uScreen, 1.));

    result.wall_height  = l2.r;
    result.dist_to_wall = l2.g;
    result.side         = l2.b;
    result.tex_num      = l2.a;

    return result;

}

/*
vec4 getShade(float dist) {
    vec4 shade = vec4(1.0);                     // couleur de base
    float factor = 1.0 - (dist / 20.0);         // plus la distance est grande, plus la couleur est sombre
    factor = max(factor, 0.15);                 // limiter le facteur de sombrement à 0,5
    shade.rgb *= factor;                        // applique le facteur à la couleur
    return shade;
}
*/

vec4 getShade(float dist) {
    return vec4(vec3(1.0-(dist/20.0)),1.0);
}

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc) {

    // Get raycast data //

    RenderData rd = extractRenderData(tc.x);

    // Get start line and end line of wall //

    float wall_y1 = (-rd.wall_height*.5 + love_ScreenSize.y*.5);
    float wall_y2 = (rd.wall_height*.5 + love_ScreenSize.y*.5);

    // Predef final color //

    vec4 color;

    // Render Walls/Sky/Ground //

    if (sc.y >= wall_y1 && sc.y <= wall_y2) { // WALLS

        vec4 shade = getShade(rd.dist_to_wall);

        if (rd.tex_num <= wallTexCount) {

            vec2 tex_coord = vec2(                          // Coordinates of the texture sample to display [0->1]
                fract(rd.side == 0 ? rd.hit_y : rd.hit_x),
                (sc.y - wall_y1) / rd.wall_height
            );

            //if (rd.ray_dir_x > 0.0 || rd.ray_dir_y < 0.0)   // Flip texture horizontally if ray is facing right
            //    tex_coord.x = 1.0 - tex_coord.x;

            color = Texel(wallTexs, vec3(tex_coord, rd.tex_num-1)) * shade;

        } else { // Non textured
            color = vec4(1.0) * shade;
        }

    } else if (sc.y < wall_y2) {            // SKY

        color = vec4(0.0, 0.1, 0.5, 1.0);

    } else if (sc.y > wall_y2) {            // GROUND

        vec4 shade = getShade((1.0-tc.y)*30.0);

        if (groundTexNum <= groundTexCount) {

            // rayDir for leftmost ray (x = 0) and rightmost ray (x = w)
            vec2 ray_dir_0 = dir.xy - plane.xy;
            vec2 ray_dir_1 = dir.xy + plane.xy;

            // Vertical position of the camera.
            float pos_z = 0.5 * love_ScreenSize.y;

            // Current y position compared to the center of the screen (the horizon)
            float p = sc.y - pos_z;

            // Horizontal distance from the camera to the floor for the current row.
            // 0.5 is the z position exactly in the middle between floor and ceiling.
            float row_distance = pos_z / p;

            // calculate the real world step vector we have to add for each x (parallel to camera plane)
            // adding step by step avoids multiplications with a weight in the inner loop
            vec2 floor_step = row_distance * (ray_dir_1 - ray_dir_0) / love_ScreenSize.x;

            // real world coordinates of the leftmost column. This will be updated as we step to the right.
            // in the process, we also obtain its fractional part in order to have coordinates ranging from 0 to 1
            vec2 floor_pos = fract(pos.xy + row_distance * ray_dir_0 + floor_step * sc.x);

            color = Texel(groundTexs, vec3(floor_pos, groundTexNum)) * shade;

        } else {
            color = vec4(0.0, 0.5, 0.1, 1.0) * shade;
        }

    }

    return color;
}