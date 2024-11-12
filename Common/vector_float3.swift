//
//  vector_float3.swift
//  TestOGLMesh
//
//  Created by Mark Lim Pak Mun on 11/11/2024.
//  Copyright © 2024 Mark Lim Pak Mun. All rights reserved.
//

import simd

extension vector_float3
{
    func toArray() -> [Float] {
        return [Float](arrayLiteral:
            self.x, self.y, self.z)
    }
}
