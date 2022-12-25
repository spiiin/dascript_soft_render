require fio
require strings
require daslib/regex
require daslib/regex_boost

var floatRegEx <- %regex~[+-]?(\d+([.]\d*)?([eE][+-]?\d+)?|[.]\d+([eE][+-]?\d+)?)%%
var intRegEx <- %regex~\d+%%

struct Model
    verts: array<float3>
    normals: array<float3>
    uv: array<float2>

    faces: array<int3>
    uvIndexes: array<int3>
    normalIndexes: array<int3>

def load_obj(fname: string): Model
    var answer: Model 
    fopen(fname,"rt") <| $(f)
        if f == null
            return
        while !feof(f)
            let curString = fgets(f)
            if length(curString) < 3
                continue
            let char1 = unsafe(character_uat(curString, 0))
            let char2 = unsafe(character_uat(curString, 1))
            //read vertex
            if char1 == 'v' && char2 == ' '
                var vert: float3
                var index = 0
                regex_foreach(floatRegEx, curString) <| $(r)
                    vert[index++] = float(slice(curString, r.x, r.y))
                    return index < 3
                answer.verts |> push(vert)
            //read normal
            if char1 == 'v' && char2 == 'n'
                var norm: float3
                var ni = 0
                regex_foreach(floatRegEx, curString) <| $(r)
                    norm[ni++] = float(slice(curString, r.x, r.y))
                    return ni < 3
                answer.normals |> push(norm)
            //read texture coordinate
            if char1 == 'v' && char2 == 't'
                var uv: float2
                var ti = 0
                regex_foreach(floatRegEx, curString) <| $(r)
                    uv[ti++] = float(slice(curString, r.x, r.y))
                    return ti < 2
                answer.uv |> push(uv)
            //read face
            if char1 == 'f' && char2 == ' '
                var face: int3
                var uvIndex: int3
                var normalIndex: int3
                var index = 0
                regex_foreach(intRegEx, curString) <| $(r)
                    let ind = int(slice(curString, r.x, r.y)) - 1
                    if index%3 == 0
                        face[index/3] = ind
                    elif index%3 == 1
                        uvIndex[index/3] = ind
                    else
                        normalIndex[index/3] =  ind
                    return ++index < 9
                answer.faces |> push(face)
                answer.uvIndexes |> push(uvIndex)
                answer.normalIndexes |> push(normalIndex)
    return <- answer
