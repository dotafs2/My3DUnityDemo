#ifndef RayBoxDis
#define RayBoxDis

// 判断ray的origin是否在包围盒内
bool IsInsideBox(float3 origin, float3 boundsMin, float3 boundsMax)
{
    return all(origin >= boundsMin) && all(origin <= boundsMax);
}

//------------------------------------------------------------------------------
// 功能：计算射线与 Axis-Aligned Bounding Box (AABB) 的相交范围（只返回距离，不返回坐标）。
//       返回值 float2 中：
//         x = 从 rayOrigin 到包围盒最近交点的距离（入口）
//         y = 射线在盒内穿行的距离（如果有交点的话）
//------------------------------------------------------------------------------
float2 RayBoxDistance(
    float3 boundsMin, // 包围盒的最小点（xMin, yMin, zMin）
    float3 boundsMax, // 包围盒的最大点（xMax, yMax, zMax）
    float3 rayOrigin, // 射线原点
    float3 invRay // 射线方向的倒数(1 / rayDir)，需要外部计算避免重复
)
{
    float3 t0 = (boundsMin - rayOrigin) * invRay;
    float3 t1 = (boundsMax - rayOrigin) * invRay;

    float3 tmin = min(t0, t1);
    float3 tmax = max(t0, t1);

    float dstA = max(max(tmin.x, tmin.y), tmin.z); // 射线在所有轴都进入 AABB 的最晚时刻
    float dstB = min(tmax.x, min(tmax.y, tmax.z)); // 射线在所有轴离开 AABB 的最早时刻

    // 射线从起点到 AABB 入口的距离
    float dstToBox = max(0, dstA);

    // 在盒子内穿行的距离
    float dstInsideBox = max(0, dstB - dstToBox);

    return float2(dstToBox, dstInsideBox);
}

//------------------------------------------------------------------------------
// 功能：与上面函数类似，但除了返回是否与 AABB 相交外，还输出具体的交点 inPos、outPos。
//       返回值：1 表示射线与 AABB 有效相交；0 表示无效（未相交或距离不合理）。
//
// 新增：如果射线原点在包围盒内，则强制 inPos = rayOrigin。
//------------------------------------------------------------------------------
float RayBoxDistance(
    float3 boundsMin, // AABB 最小点
    float3 boundsMax, // AABB 最大点
    float3 rayOrigin, // 射线原点
    float3 ray, // 射线方向（注意这里不是 1/ray，而是真正的方向）
    out float3 inPos, // 射线与 AABB 的入口点世界坐标
    out float3 outPos // 射线与 AABB 的出口点世界坐标
)
{
    // 1. 先判断射线原点是否在 AABB 内，如果是，inPos 直接设置为射线原点
    bool originInside = IsInsideBox(rayOrigin, boundsMin, boundsMax);

    // 2. 计算射线方向的倒数，复用之前的 RayBoxDistance 函数。
    float3 invRay = 1.0f / ray;

    // 取得进入 AABB 的距离(x) 和在内部行走的距离(y)
    float2 rayBoxDst = RayBoxDistance(boundsMin, boundsMax, rayOrigin, invRay);

    // 3. 如果原点在 AABB 内，则强制 inPos = rayOrigin；否则按原有逻辑计算
    if (originInside)
    {
        inPos = rayOrigin; // 射线原点在盒子内
    }
    else
    {
        inPos = rayOrigin + ray * rayBoxDst.x;
    }

    // outPos：从 inPos 出发，在盒子内再走 rayBoxDst.y 的路程
    outPos = inPos + ray * rayBoxDst.y;

    // 如果入口距离大于 1，通常表示与我们定义的射线段不符，可视作无效碰撞
    if (rayBoxDst.x > 1.0f && !originInside)
        return 0.0f;

    // 如果 入口距离+在内部距离 > 1，说明出口点超过射线段长度，则把出口点限定在 rayOrigin + ray
    if (rayBoxDst.x + rayBoxDst.y > 1.0f)
    {
        outPos = rayOrigin + ray;
    }

    // 如果在盒子内穿行距离为 0，表示不相交或仅擦边，也视为无效
    if (rayBoxDst.y == 0.0f)
    {
        // 但要注意：如果原点就在盒内，dstBoxDst.y=0 仅可能意味着朝外发射时刚好擦边。
        // 看你是否要特殊处理这种情况，这里保持与原逻辑一致，依然视为无效：
        return 0.0f;
    }

    // 返回 1 表示射线确实与 AABB 相交
    return 1.0f;
}

#endif
