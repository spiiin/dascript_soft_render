require fio
require stbimage
require daslib/safe_addr

struct Tex
    width, height, components: int
    data: array<uint8>
    dataPtr: uint8?

def load_tex(fname: string): Tex
    var answer: Tex 
    var x, y, comp : int
    answer.dataPtr = stbi_load(fname, safe_addr(x), safe_addr(y), safe_addr(comp), 0)
    answer.width = x
    answer.height = y
    answer.components = comp
    return <- answer

def free_tex(tex: Tex)
    stbi_image_free(tex.dataPtr)

def get_pixel(tex: Tex; uv: int2)
    var baseIndex = ((tex.height-uv.y) * tex.width + uv.x) * tex.components
    unsafe
        let temp1 = tex.dataPtr[baseIndex]
        let temp2 = tex.dataPtr[baseIndex+1]
        let temp3 = tex.dataPtr[baseIndex+2]
        return float3(float(temp1)/255.0f, float(temp2)/255.0f, float(temp3)/255.0f)