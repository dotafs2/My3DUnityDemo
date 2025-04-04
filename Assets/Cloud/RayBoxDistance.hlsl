#ifndef RayBoxDis
#define RayBoxDis

// 看看ray的origin是不是在包围盒内
bool IsInsideBox(float3 origin, float3 boundsMin, float3 boundsMax) {
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
    float3 t0, t1, tmin, tmax;
    float dstA, dstB, dstAdstB, dstToBox, dstInsideBox = 0;

    // 分别计算射线与 AABB 在 X/Y/Z 三个维度的 parametric t0、t1（射线参数），
    // t0 是射线与 boundsMin 平面的碰撞时间，t1 是射线与 boundsMax 平面的碰撞时间。
    t0 = (boundsMin - rayOrigin) * invRay;
    t1 = (boundsMax - rayOrigin) * invRay;

    // tmin、tmax 分别是三维上各轴最小/最大交点的时间。
    // 这里用 min/max 是因为射线可能正向/反向，与边界相交顺序不一定。
    tmin = min(t0, t1);
    tmax = max(t0, t1);

    // dstA：求出三个轴 tmin 中的最大值，代表射线在所有轴都进入 AABB 的“最晚”时刻（入口）。
    dstA = max(max(tmin.x, tmin.y), tmin.z);
    // dstB：求出三个轴 tmax 中的最小值，代表射线离开 AABB 的“最早”时刻（出口）。
    dstB = min(tmax.x, min(tmax.y, tmax.z));

    // dstToBox = 射线进入盒子所需的距离，如果 dstA 小于 0 表示起点就在盒子内，则距离记为 0。
    dstToBox = max(0, dstA);

    // 射线在盒子内行走的距离。dstB - dstToBox 是进入与退出的差值，如果小于 0 就表示无效（不相交）。
    dstInsideBox = max(0, dstB - dstToBox);

    // x: 射线从起点到 AABB 的入口距离
    // y: 射线在 AABB 内部穿越的距离
    
    
    
    
    return float2(dstToBox, dstInsideBox);
}


//------------------------------------------------------------------------------
// 功能：与上面函数类似，但除了返回是否与 AABB 相交外，还输出具体的交点 inPos、outPos。
//       返回值：1 表示射线与 AABB 有效相交；0 表示无效（未相交或距离不合理）。
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
    // 先计算射线方向的倒数，复用之前的 RayBoxDistance 函数。
    float3 invRay = 1.0 / ray;

    // 取得进入 AABB 的距离(x) 和在内部行走的距离(y)
    float2 rayBoxDst = RayBoxDistance(boundsMin, boundsMax, rayOrigin, invRay);

    // inPos：入口点 = rayOrigin + 射线方向 * 入口距离
    inPos = rayOrigin + ray * rayBoxDst.x;
    
    // outPos：出口点 = inPos + 射线方向 * 射线在盒内穿行的距离
    outPos = inPos + ray * rayBoxDst.y;

    // 如果入口距离大于 1，通常表示和我们定义的射线段（可能是 0~1 的范围）不符，可以视作无效碰撞
    if (rayBoxDst.x > 1)
        return 0;
        
    // 如果 入口距离+在内部距离 > 1，说明出口点超过射线段长度，则把出口点限定在 rayOrigin + ray。
    // 这通常和“射线段”长短的定义有关，如果把射线定义为 0~1，那么超过 1 的部分就不再计算。
    if (rayBoxDst.x + rayBoxDst.y > 1)
        outPos = rayOrigin + ray;

    // 如果在盒子内穿行距离为 0，表示要么不相交，要么仅仅擦边，也视为无效。
    if (rayBoxDst.y == 0)
        return 0;

    // 返回 1 表示射线确实与 AABB 相交，且 inPos、outPos 有效。
    return 1;
}

#endif
