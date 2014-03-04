-- authors: Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

local funccall = "([A-Za-z_][A-Za-z0-9_]*)%s*"

return {
  exts = {"hlsl","fx","fxh",},
  lexer = wxstc.wxSTC_LEX_CPP,
  apitype = "hlsl",
  sep = "%.",
  linecomment = "//",
  
  isfncall = function(str)
    return string.find(str, funccall .. "%(")
  end,

  isfndef = function(str)
    local l
    local s,e,cap = string.find(str,"^%s*([A-Za-z0-9_]+%s+[A-Za-z0-9_]+%s*%(.+%))")
    if (not s) then
      s,e,cap = string.find(str,"^%s*([A-Za-z0-9_]+%s+[A-Za-z0-9_]+)%s*%(")
    end
    if (cap and (string.find(cap,"^return") or string.find(cap,"else"))) then return end
    return s,e,cap,l
  end,

  lexerstyleconvert = {
    text = {wxstc.wxSTC_C_IDENTIFIER,},

    lexerdef = {wxstc.wxSTC_C_DEFAULT,},
    comment = {wxstc.wxSTC_C_COMMENT,
      wxstc.wxSTC_C_COMMENTLINE,
      wxstc.wxSTC_C_COMMENTDOC,},
    stringtxt = {wxstc.wxSTC_C_STRING,
      wxstc.wxSTC_C_CHARACTER,
      wxstc.wxSTC_C_VERBATIM,},
    stringeol = {wxstc.wxSTC_C_STRINGEOL,},
    preprocessor= {wxstc.wxSTC_C_PREPROCESSOR,},
    operator = {wxstc.wxSTC_C_OPERATOR,},
    number = {wxstc.wxSTC_C_NUMBER,},

    keywords0 = {wxstc.wxSTC_C_WORD,},
    keywords1 = {wxstc.wxSTC_C_WORD2,},
  },

  keywords = {
    [[break continue if else switch return for while do typedef namespace true false compile
    const void struct static extern register volatile inline target nointerpolation shared uniform row_major column_major snorm unorm 
    bool bool1 bool2 bool3 bool4 int int1 int2 int3 int4 uint uint1 uint2 uint3 uint4 half half1 half2 half3 half4 float float1 float2 float3 float4 double double1 double2 double3 double4
    matrix bool1x1 bool1x2 bool1x3 bool1x4 bool2x1 bool2x2 bool2x3 bool2x4 bool3x1 bool3x2 bool3x3 bool3x4 bool4x1 bool4x2 bool4x3 bool4x4
    int1x1 int1x2 int1x3 int1x4 int2x1 int2x2 int2x3 int2x4 int3x1 int3x2 int3x3 int3x4 int4x1 int4x2 int4x3 int4x4 uint1x1 uint1x2 uint1x3 uint1x4 
    uint2x1 uint2x2 uint2x3 uint2x4 uint3x1 uint3x2 uint3x3 uint3x4 uint4x1 uint4x2 uint4x3 uint4x4 half1x1 half1x2 half1x3 half1x4 half2x1 half2x2 
    half2x3 half2x4 half3x1 half3x2 half3x3 half3x4 half4x1 half4x2 half4x3 half4x4 float1x1 float1x2 float1x3 float1x4 float2x1 float2x2 float2x3
    float2x4 float3x1 float3x2 float3x3 float3x4 float4x1 float4x2 float4x3 float4x4 double1x1 double1x2 double1x3 double1x4 double2x1 double2x2 
    double2x3 double2x4 double3x1 double3x2 double3x3 double3x4 double4x1 double4x2 double4x3 double4x4 cbuffer groupshared SamplerState 
    in out inout vector matrix interface class point triangle line lineadj triangleadj unsigned
    pass technique technique10 technique11
    
    Texture Texture1D Texture1DArray Texture2D Texture2DArray Texture2DMS Texture2DMSArray Texture3D TextureCube RWTexture1D RWTexture1DArray RWTexture2D RWTexture2DArray RWTexture3D 
    Buffer StructuredBuffer AppendStructuredBuffer ConsumeStructuredBuffer RWBuffer RWStructuredBuffer ByteAddressBuffer RWByteAddressBuffer PointStream TriangleStream LineStream InputPatch OutputPatch
    ]],

    [[unroll loop flatten branch allow_uav_condition earlydepthstencil domain instance maxtessfactor outputcontrolpoints outputtopology partitioning patchconstantfunc numthreads maxvertexcount precise
    
    SV_DispatchThreadID SV_DomainLocation SV_GroupID SV_GroupIndex SV_GroupThreadID SV_GSInstanceID SV_InsideTessFactor SV_OutputControlPointID SV_Coverage SV_Depth SV_Position SV_IsFrontFace SV_RenderTargetArrayIndex SV_SampleIndex SV_ViewportArrayIndex SV_InstanceID SV_PrimitiveID SV_VertexID    
    SV_ClipDistance SV_CullDistance SV_Target
    
    abs acos all AllMemoryBarrier AllMemoryBarrierWithGroupSync any asdouble asfloat asin asint asuint atan atan2 ceil clamp clip cos cosh countbits cross ddx ddx_coarse ddx_fine ddy ddy_coards ddy_fine degrees determinant DeviceMemoryBarrier DeviceMemoryBarrierWithGroupSync distance dot dst EvaluateAttributeAtCentroid EvaluateAttributeAtSample EvaluateAttributeSnapped exp exp2 f16tof32 f32tof16 faceforward firstbithigh firstbitlow floor fmod frac frexp fwidth GetRenderTargetSampleCount GetRenderTargetSamplePosition GroupMemoryBarrier GroupMemoryBarrierWithGroupSync InterlockedAdd InterlockedAnd InterlockedCompareExchange InterlockedExchange InterlockedMax InterlockedMin IntterlockedOr InterlockedXor isfinite isinf isnan ldexp length lerp lit log log10 log2 mad max min modf mul normalize pow Process2DQuadTessFactorsAvg Process2DQuadTessFactorsMax Process2DQuadTessFactorsMin ProcessIsolineTessFactors ProcessQuadTessFactorsAvg ProcessQuadTessFactorsMax ProcessQuadTessFactorsMin ProcessTriTessFactorsAvg ProcessTriTessFactorsMax ProcessTriTessFactorsMin radians rcp reflect refract reversebits round rsqrt saturate sign sin sincos sinh smoothstep sqrt step tan tanh transpose trunc
    Append RestartStrip CalculateLevelOfDetail CalculateLevelOfDetailUnclamped GetDimensions GetSamplePosition Load Sample SampleBias SampleCmp SampleCmpLevelZero SampleGrad SampleLevel Load2 Load3 Load4 Consume Store Store2 Store3 Store4 DecrementCounter IncrementCounter mips Gather GatherRed GatherGreen GatherBlue GatherAlpha GatherCmp GatherCmpRed GatherCmpGreen GatherCmpBlue GatherCmpAlpha
    
    x y z w
    xxxx xxxy xxxz xxxw xxyx xxyy xxyz xxyw xxzx xxzy
    xxzz xxzw xxwx xxwy xxwz xxww xyxx xyxy xyxz xyxw
    xyyx xyyy xyyz xyyw xyzx xyzy xyzz xyzw xywx xywy
    xywz xyww xzxx xzxy xzxz xzxw xzyx xzyy xzyz xzyw
    xzzx xzzy xzzz xzzw xzwx xzwy xzwz xzww xwxx xwxy
    xwxz xwxw xwyx xwyy xwyz xwyw xwzx xwzy xwzz xwzw
    xwwx xwwy xwwz xwww yxxx yxxy yxxz yxxw yxyx yxyy
    yxyz yxyw yxzx yxzy yxzz yxzw yxwx yxwy yxwz yxww
    yyxx yyxy yyxz yyxw yyyx yyyy yyyz yyyw yyzx yyzy
    yyzz yyzw yywx yywy yywz yyww yzxx yzxy yzxz yzxw
    yzyx yzyy yzyz yzyw yzzx yzzy yzzz yzzw yzwx yzwy
    yzwz yzww ywxx ywxy ywxz ywxw ywyx ywyy ywyz ywyw
    ywzx ywzy ywzz ywzw ywwx ywwy ywwz ywww zxxx zxxy
    zxxz zxxw zxyx zxyy zxyz zxyw zxzx zxzy zxzz zxzw
    zxwx zxwy zxwz zxww zyxx zyxy zyxz zyxw zyyx zyyy
    zyyz zyyw zyzx zyzy zyzz zyzw zywx zywy zywz zyww
    zzxx zzxy zzxz zzxw zzyx zzyy zzyz zzyw zzzx zzzy
    zzzz zzzw zzwx zzwy zzwz zzww zwxx zwxy zwxz zwxw
    zwyx zwyy zwyz zwyw zwzx zwzy zwzz zwzw zwwx zwwy
    zwwz zwww wxxx wxxy wxxz wxxw wxyx wxyy wxyz wxyw
    wxzx wxzy wxzz wxzw wxwx wxwy wxwz wxww wyxx wyxy
    wyxz wyxw wyyx wyyy wyyz wyyw wyzx wyzy wyzz wyzw
    wywx wywy wywz wyww wzxx wzxy wzxz wzxw wzyx wzyy
    wzyz wzyw wzzx wzzy wzzz wzzw wzwx wzwy wzwz wzww
    wwxx wwxy wwxz wwxw wwyx wwyy wwyz wwyw wwzx wwzy
    wwzz wwzw wwwx wwwy wwwz wwww xy xz yz xyz
    xw yw xyw zw xzw yzw xyzw 
    ]],

  },
}
