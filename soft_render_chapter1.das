require stbimage
require daslib/math_boost

require obj_loader

let width = 800
let height = 800

def line(var x0, y0, x1, y1: int; var backbuffer: array<float3>; color: float3)
    var steep = false
    if abs(x1-x0) < abs(y1-y0)
        swap(x0, y0)
        swap(x1, y1)
        steep = true
    if x0 > x1
        swap(x0, x1)
        swap(y0, y1)

    let dx = x1-x0
    let dy = y1-y0
    let derror2 = abs(dy)*2
    var error2 = 0
    var x = x0
    var y = y0
    while x <= x1
        if steep
            backbuffer[x*width + y] = color
        else
            backbuffer[y*width + x] = color
        error2 += derror2
        if error2 > dx
            y += y1 > y0 ? 1:-1
            error2 -= dx*2
        x++

[export]
def main
    //init
    var model <- load_obj("african_head.obj")
    var backbuffer: array<float3>
    resize(backbuffer,width*(height+1))

    //draw
    let fwidth = float(width)
    let fheight = float(height)
    for face in model.faces
        for i in range(3)
            let v0 = model.verts[face[i]]
            let v1 = model.verts[face[(i+1)%3]]
            let x0 = int((v0.x + 1.0f) * fwidth / 2.0f)
            let y0 = int((v0.y + 1.0f) * fheight / 2.0f)
            let x1 = int((v1.x + 1.0f) * fwidth / 2.0f)
            let y1 = int((v1.y + 1.0f) * fheight / 2.0f)
            line(x0, y0, x1, y1, backbuffer, float3(1.0f, 1.0f, 1.0f))

    //test fill triangles


    //save to png
    var pixels : array<uint>
    pixels |> reserve(width*height)
    for y in range(height)
        for x in range(width)
            let srgb = float4(backbuffer[x + (height-1-y)*width].xyz, 1.0f)
            pixels |> push <| RGBA_TO_UCOLOR(srgb)
    unsafe
        stbi_write_png( "soft_render.png", width, height, 4, addr(pixels[0]), width*4  )