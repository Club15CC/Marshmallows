/** 
 \addtogroup Marshmallows
 \author     Created by Hari Karam Singh on 15/08/2012.
 \copyright  Copyright (c) 2012 Club 15CC. All rights reserved.
 @{ 
 */

#import "AUMUnitAbstract.h"

#import "MarshmallowCocoa.h"

#import "AUMErrorChecking.h"



/////////////////////////////////////////////////////////////////////////
#pragma mark - AUMUnitAbstract
/////////////////////////////////////////////////////////////////////////

@implementation AUMUnitAbstract


/////////////////////////////////////////////////////////////////////////
#pragma mark - Init
/////////////////////////////////////////////////////////////////////////
- (id)init
{
    self = [super init];
    if (self) {
        _inputStreamFormatsQueue = [NSMutableDictionary new];
        _outputStreamFormatsQueue = [NSMutableDictionary new];
        _renderCallbacksQueue = [NSMutableDictionary new];
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Property Accessors
/////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////

- (void)setStreamFormat:(AudioStreamBasicDescription)aStreamFormat forInputBus:(NSUInteger)aBusNum
{
    // If added to the graph already then set the AU property...
    if (_hasBeenAddedToGraph) {
        _(AudioUnitSetProperty(_audioUnitRef,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               aBusNum,
                               &aStreamFormat,
                               sizeof(aStreamFormat)),
          [NSString stringWithFormat:@"Failed to set stream format on input bus %i of %@", aBusNum, self]);
    } else {
        // Add it to our dictionary
        NSValue *asValue = [NSValue value:&aStreamFormat withObjCType:@encode(AudioStreamBasicDescription)];
        [_inputStreamFormatsQueue setObject:asValue forIntegerKey:aBusNum];
    }
}

/////////////////////////////////////////////////////////////////////////

- (void)setStreamFormat:(AudioStreamBasicDescription)aStreamFormat forOutputBus:(NSUInteger)aBusNum
{
    // If added to the graph already then set the AU property...
    if (_hasBeenAddedToGraph) {
        _(AudioUnitSetProperty(_audioUnitRef,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Output,
                               aBusNum,
                               &aStreamFormat,
                               sizeof(aStreamFormat)),
          [NSString stringWithFormat:@"Failed to set stream format on output bus %i of %@", aBusNum, self]);
    } else {
        
        // Add it to our dictionary
        NSValue *asValue = [NSValue value:&aStreamFormat withObjCType:@encode(AudioStreamBasicDescription)];
        [_outputStreamFormatsQueue setObject:asValue forIntegerKey:aBusNum];
    }
}

/////////////////////////////////////////////////////////////////////////

- (void)setRenderCallback:(AURenderCallbackStruct)aRenderCallback forInputBus:(NSUInteger)aBusNum
{
    // If added to the graph already then set the AU property...
    if (_hasBeenAddedToGraph) {
        _(AudioUnitSetProperty(_audioUnitRef,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               aBusNum,
                               &aRenderCallback,
                               sizeof(aRenderCallback)),
          
          [NSString stringWithFormat:@"Failed to set render callback on input bus %i of %@", aBusNum, self]);
    } else {
        
        // Add it to our dictionary
        NSValue *asValue = [NSValue value:&aRenderCallback withObjCType:@encode(AURenderCallbackStruct)];
        [_renderCallbacksQueue setObject:asValue forIntegerKey:aBusNum];
    }
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - AUMUnitProtocol Fulfillment
/////////////////////////////////////////////////////////////////////////
/** @name  AUMUnitProtocol Fulfillment */

@synthesize _graphRef=_graphRef;
@synthesize _nodeRef=_nodeRef;
@synthesize _audioUnitRef=_audioUnitRef;

/////////////////////////////////////////////////////////////////////////

/** Subclasses must define this method to indicate the kind of AU component they are
    \abstract */
- (AudioComponentDescription)_audioComponentDescription
{
    AudioComponentDescription r;
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method must be overridden by subclass."];
    return r;
}

/////////////////////////////////////////////////////////////////////////

/** Handles late binding of stream formats and callbacks.  Subclasses should call super */
- (void)_nodeWasAddedToGraph
{
    // Indicate
    _hasBeenAddedToGraph = YES;
    
    // Loop through our queues and set the AU properties
    
    // INPUT STREAM FORMATS
    for (NSNumber *key in _inputStreamFormatsQueue) {
        
        // Unwrap values
        NSInteger busNum = [key integerValue];
        AudioStreamBasicDescription format;
        [(NSValue *)[_inputStreamFormatsQueue objectForKey:key] getValue:&format];
        
        _(AudioUnitSetProperty(_audioUnitRef,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               busNum,
                               &format,
                               sizeof(format)),
          [NSString stringWithFormat:@"Failed to set stream format on input bus %i of %@", busNum, self]);
    }
    [_inputStreamFormatsQueue removeAllObjects];     // Clear the queue
    
    // OUTPUT STREAM FORMATS
    for (NSNumber *key in _outputStreamFormatsQueue) {
        
        // Unwrap values
        NSUInteger busNum = [key unsignedIntegerValue];
        AudioStreamBasicDescription format;
        [(NSValue *)[_outputStreamFormatsQueue objectForKey:key] getValue:&format];
        
        _(AudioUnitSetProperty(_audioUnitRef,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Output,
                               busNum,
                               &format,
                               sizeof(format)),
          [NSString stringWithFormat:@"Failed to set stream format on output bus %i of %@", busNum, self]);
    }
    [_outputStreamFormatsQueue removeAllObjects];     // Clear the queue

    // INPUT RENDER CALLBACKS
    for (NSNumber *key in _renderCallbacksQueue) {
        
        // Unwrap values
        NSUInteger busNum = [key unsignedIntegerValue];
        AURenderCallbackStruct callback;
        [(NSValue *)[_renderCallbacksQueue objectForKey:key] getValue:&callback];
        
        _(AudioUnitSetProperty(_audioUnitRef,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               busNum,
                               &callback,
                               sizeof(callback)),
          [NSString stringWithFormat:@"Failed to set render callback on input bus %i of %@", busNum, self]);
    }
    [_renderCallbacksQueue removeAllObjects];     // Clear the queue
}

/// @}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////



@end

/// @}