require stbimage
require daslib/math_boost
require daslib/defer

require obj_loader
require tex_loader

let width = 800
let height = 800
let depth = 255
let screen_size = float2(width, height)

let camera_proj = -1.0f //object in space [-1.0 .. 1.0]
let camera_pos = look_at_rh(float3(0.1f, 0.1f, 0.5f), float3(0.0f, 0.0f, 0.0f), float3(0.0f, 1.0, 0.0f))

let light_dir = normalize(float3(1.0f, 0.0f, -1.0f))

def screen_coords(world_coord: float3)
    let world_coord_proj = world_coord / (1.0f - (world_coord.z + camera_proj))
    let view_coord = (camera_pos * float4(world_coord_proj, 1.0f)).xyz
    return (view_coord + float3(1.0f)) * float3(screen_size, float(depth)) * float3(0.5f)

def tex_pixel_coords(tex_coord: float2; tex: Tex)
    return int2(tex_coord.x * float(tex.width), tex_coord.y * float(tex.height))

def barycentric(A, B, C, P: float2) : float3
    let u = cross(float3(C.x - A.x, B.x - A.x, A.x - P.x), float3(C.y - A.y, B.y - A.y, A.y - P.y))
    if abs(u[2]) > 1e-2
        return float3(1.0f - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z)
    return float3(-1.0f, 1.0f, 1.0f)

var varying_intensity: float3
var varying_texCoord: float2[3]

def vertex_shader(model: Model; tex: Tex; i, nth: int): float3
    let face = model.faces[i]
    let uvIndex = model.uvIndexes[i]
    let normalIndex = model.normalIndexes[i]
    let v0 = model.verts[face[nth]]
    varying_texCoord[nth] = float2(tex_pixel_coords(model.uv[uvIndex[nth]], tex))
    varying_intensity[nth] = max(-dot(model.normals[normalIndex[nth]], light_dir), 0.0f)
    return screen_coords(v0)

def pixel_shader(bar: float3; tex: Tex)
    let uv = varying_texCoord[0] * bar[0] + varying_texCoord[1] * bar[1] + varying_texCoord[2] * bar[2]
    return tex |> get_pixel(int2(uv)) * dot(bar, varying_intensity)

def triangle(var t0, t1, t2: float3; tex: Tex; var backbuffer: array<float3>; var zbuffer: array<int>)
    let bboxMin = int2(min(t0.x, min(t1.x, t2.x)), min(t0.y, min(t1.y, t2.y)))
    let bboxMax = int2(max(t0.x, max(t1.x, t2.x)), max(t0.y, max(t1.y, t2.y)))
    var y = bboxMin.y
    while y <= bboxMax.y
        var x = bboxMin.x
        while x <= bboxMax.x
            let c = barycentric(float2(t0.xy), float2(t1.xy), float2(t2.xy), float2(x,y))
            let z = int(t0.z*c.x + t1.z*c.y + t2.z*c.z)
            let idx = y * width + x
            if c.x >= 0.0f && c.y >= 0.0f && c.z >= 0.0f && z > zbuffer[idx]
                let color = pixel_shader(c, tex)
                zbuffer[idx] = z
                backbuffer[idx] = color
            x++
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
    for i in range(length(model.faces))
        let v0t = vertex_shader(model, tex, i, 0)
        let v1t = vertex_shader(model, tex, i, 1)
        let v2t = vertex_shader(model, tex, i, 2)
        triangle(v0t, v1t, v2t, tex, backbuffer, zbuffer)

    //save to png
    var pixels : array<uint>
    pixels |> reserve(width*height)
    for y in range(height)
        for x in range(width)
            let srgb = float4(backbuffer[x + (height-1-y)*width].xyz, 1.0f)
            pixels |> push <| RGBA_TO_UCOLOR(srgb)
    unsafe
        stbi_write_png("soft_render.png", width, height, 4, addr(pixels[0]), width*4)