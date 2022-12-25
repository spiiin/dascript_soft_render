require stbimage
require daslib/math_boost

require obj_loader

let width = 800
let height = 800
let screen_size = float2(width, height)

let light_dir = float3(0.0f, 0.0f, -1.0f)

def triangle(var t0, t1, t2: int2;  var backbuffer: array<float3>; color: float3)
    if (t0.y == t1.y) && (t0.y == t2.y)
        return //degenerate triangle
    
    if (t0.y > t1.y) { swap(t0, t1); }
    if (t0.y > t2.y) { swap(t0, t2); }
    if (t1.y > t2.y) { swap(t1, t2); }

    let total_height = t2.y - t0.y
    var y = 0
    while y < total_height
        let second_half = y > t1.y-t0.y || t1.y == t0.y
        let segment_height = second_half ? t2.y - t1.y : t1.y - t0.y
        let alpha = float(y) / float(total_height)
        let beta = float(y - (second_half ? t1.y - t0.y : 0)) / float(segment_height)
        var A = int2(float2(t0) + float2(t2 - t0) * float2(alpha))
        var B = second_half ? int2(float2(t1) + float2(t2 - t1) * float2(beta)) : int2(float2(t0) + float2(t1 - t0) * float2(beta))
        if (A.x > B.x) { swap(A, B); }
        for x in range(A.x, B.x)
            backbuffer[(t0.y+y)*width + x] = color
        y++

def screen_coords(world_coord: float3)
    return int2((world_coord.xy + float2(1.0f)) * screen_size * float2(0.5f))

[export]
def main
    //init
    var model <- load_obj("african_head.obj")
    var backbuffer: array<float3>
    resize(backbuffer,width*(height+1))

    //draw
    for face in model.faces
        let v0 = model.verts[face[0]]
        let v1 = model.verts[face[1]]
        let v2 = model.verts[face[2]]
        let v0t = screen_coords(v0)
        let v1t = screen_coords(v1)
        let v2t = screen_coords(v2)
        let normal = normalize(cross(v2-v0, v1-v0))
        let intensity = dot(normal, light_dir)
        if intensity > 0.0f
            triangle(v0t, v1t, v2t, backbuffer, float3(intensity))

    //save to png
    var pixels : array<uint>
    pixels |> reserve(width*height)
    for y in range(height)
        for x in range(width)
            let srgb = float4(backbuffer[x + (height-1-y)*width].xyz, 1.0f)
            pixels |> push <| RGBA_TO_UCOLOR(srgb)
    unsafe
        stbi_write_png( "soft_render.png", width, height, 4, addr(pixels[0]), width*4  )