require stbimage
require daslib/math_boost
require daslib/defer

require obj_loader
require tex_loader

let width = 800
let height = 800
let depth = 255
let screen_size = float2(width, height)
let camera_dist = -1.5f //object in space [-1.0 .. 1.0]

let light_dir = float3(0.0f, 0.0f, -1.0f)

def lerpi(a, b: int2; part:float)
    return int2(float2(a) + float2(b - a) * part)

def lerpi(a, b: int3; part:float)
    return int3(float3(a) + float3(b - a) * part)

def screen_coords(world_coord: float3)
    let world_coord_proj = world_coord / (1.0f - (world_coord.z + camera_dist))
    return int3((world_coord_proj + float3(1.0f)) * float3(screen_size, float(depth)) * float3(0.5f))

def tex_pixel_coords(tex_coord: float2; tex: Tex)
    return int2(tex_coord.x * float(tex.width), tex_coord.y * float(tex.height))

def triangle(var t0, t1, t2: int3; var uv0, uv1, uv2: int2; tex: Tex; var backbuffer: array<float3>; var zbuffer: array<int>; intensity: float3)
    if (t0.y == t1.y) && (t0.y == t2.y)
        return //degenerate triangle
    
    if (t0.y > t1.y) { swap(t0, t1); swap(uv0, uv1); }
    if (t0.y > t2.y) { swap(t0, t2); swap(uv0, uv2); }
    if (t1.y > t2.y) { swap(t1, t2); swap(uv1, uv2); }

    let total_height = t2.y - t0.y
    var y = 0
    while y < total_height
        let second_half = y > t1.y-t0.y || t1.y == t0.y
        let segment_height = second_half ? t2.y - t1.y : t1.y - t0.y
        let alpha = float(y) / float(total_height)
        let beta = float(y - (second_half ? t1.y - t0.y : 0)) / float(segment_height)
        var A = lerpi(t0, t2, alpha)
        var B = second_half ? lerpi(t1, t2, beta) : lerpi(t0, t1, beta)
        var uvA = lerpi(uv0, uv2, alpha)
        var uvB = second_half ? lerpi(uv1, uv2, beta) : lerpi(uv0, uv1, beta)
        if (A.x > B.x) { swap(A, B); swap(uvA, uvB); }
        for x in range(A.x, B.x)
            let phi = B.x==A.x ? 1.0f : float(x-A.x)/float(B.x-A.x)
            let P = lerpi(A, B, phi)
            let uvP = lerpi(uvA, uvB, phi)
            let idx = P.y*width + P.x
            if idx >= 0 && idx < length(zbuffer) && zbuffer[idx] < P.z
                zbuffer[idx] = P.z
                let color = get_pixel(tex, uvP)
                backbuffer[idx] = color * intensity
        y++

[export]
def main
    //init
    var model <- load_obj("african_head.obj")
    var tex <- load_tex("african_head_diffuse.png"); defer_delete(tex)
    let fullsize = width*(height+1)
    var backbuffer: array<float3>
    resize(backbuffer, fullsize)
    var zbuffer: array<int>
    resize(zbuffer, fullsize)

    //draw
    for face, uvIndex in model.faces, model.uvIndexes
        let v0 = model.verts[face[0]]
        let v1 = model.verts[face[1]]
        let v2 = model.verts[face[2]]
        let normal = normalize(cross(v2-v0, v1-v0))
        let intensity = dot(normal, light_dir)
        if intensity > 0.0f
            let v0t = screen_coords(v0)
            let v1t = screen_coords(v1)
            let v2t = screen_coords(v2)
            let t0 = tex_pixel_coords(model.uv[uvIndex[0]], tex)
            let t1 = tex_pixel_coords(model.uv[uvIndex[1]], tex)
            let t2 = tex_pixel_coords(model.uv[uvIndex[2]], tex)
            triangle(v0t, v1t, v2t, t0, t1, t2, tex, backbuffer, zbuffer, float3(intensity))

    //save to png
    var pixels : array<uint>
    pixels |> reserve(width*height)
    for y in range(height)
        for x in range(width)
            let srgb = float4(backbuffer[x + (height-1-y)*width].xyz, 1.0f)
            pixels |> push <| RGBA_TO_UCOLOR(srgb)
    unsafe
        stbi_write_png( "soft_render.png", width, height, 4, addr(pixels[0]), width*4  )