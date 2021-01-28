/****************************************************************************
Copyright (c) 2020 Xiamen Yaji Software Co., Ltd.

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
#include "MTLStd.h"

#include "MTLQueue.h"
#include "MTLDevice.h"
#include "MTLCommandBuffer.h"

namespace cc {
namespace gfx {

CCMTLQueue::CCMTLQueue(Device *device)
: Queue(device) {
}

bool CCMTLQueue::initialize(const QueueInfo &info) {
    _type = info.type;

    return true;
}

void CCMTLQueue::destroy() {
}

void CCMTLQueue::submit(CommandBuffer *const *cmdBuffs, uint count) {
    for (uint i = 0u; i < count; ++i) {
        CCMTLCommandBuffer *cmdBuffer = (CCMTLCommandBuffer *)cmdBuffs[i];
        _numDrawCalls += cmdBuffer->getNumDrawCalls();
        _numInstances += cmdBuffer->getNumInstances();
        _numTriangles += cmdBuffer->getNumTris();
        id<MTLCommandBuffer> mtlCmdBuffer = cmdBuffer->getMTLCommandBuffer();
        
        if (i < count-1) {
            [mtlCmdBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
                [commandBuffer release];
            }];
        }
        else {
            // Must do present before commit last command buffer.
            CCMTLDevice* device = (CCMTLDevice*)_device;
            id<CAMetalDrawable> currDrawable = (id<CAMetalDrawable>)device->getCurrentDrawable();
            [mtlCmdBuffer presentDrawable:currDrawable];
            [mtlCmdBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
                [commandBuffer release];
                device->presentCompleted();
            }];
            device->disposeCurrentDrawable();
        }
        [mtlCmdBuffer commit];
    }
}

} // namespace gfx
} // namespace cc
